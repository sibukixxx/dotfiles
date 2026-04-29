#!/usr/bin/env node
/**
 * report.mjs - CloudWatch + Performance Insights 統合レポートスクリプト
 *
 * bash + jq 依存を排除し、Node.js のみで動作する。
 * aws CLI を child_process.execFile で呼び出し、JSON をネイティブ解析。
 *
 * Usage:
 *   node report.mjs --mode weekly   # CW + PI フルレポート (default)
 *   node report.mjs --mode pi       # PI のみ
 *   node report.mjs --mode cw       # CW のみ
 *
 * Options:
 *   --start <ISO8601>      開始時刻 (default: 7日前 00:00 JST → UTC)
 *   --end <ISO8601>        終了時刻 (default: 本日 00:00 JST → UTC)
 *   --period <seconds>     CW メトリクス期間 (default: 3600)
 *   --pi-period <seconds>  PI メトリクス期間 (default: pi=300, weekly=3600)
 *   --output <path>        出力先 (default: モードに応じて自動設定)
 *   --no-fetch             AWS API を呼ばず保存済み JSON からレポート生成
 *
 * JSON キャッシュ:
 *   AWS レスポンスは常に /tmp/cw_report/json/ に保存される。
 *   --no-fetch でキャッシュから再生成可能（デバッグ用）。
 */
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname } from "node:path";

const execFileAsync = promisify(execFile);

// ============================================================
// Section 1: Constants & Config
// ============================================================

const PROFILE = "mt-prd-toscana-ro";
const REGION = "ap-northeast-1";
const REGION_CF = "us-east-1";
const JSON_DIR = "/tmp/cw_report/json";
const JST_OFFSET = 9 * 60 * 60 * 1000;

const CF_DIMS = [
  { Name: "DistributionId", Value: "E3PUSIMLRW3VNV" },
  { Name: "Region", Value: "Global" },
];
const ALB_DIMS = [{ Name: "LoadBalancer", Value: "app/prd-toscana-api-alb/f79d1326c493cee8" }];
const ECS_DIMS = [
  { Name: "ClusterName", Value: "prd-toscana-api" },
  { Name: "ServiceName", Value: "prd-toscana-api" },
];
const RDS_CLUSTER_PREFIX = "prd-toscana-api-cluster";
const RDS_CLUSTER_ID = "prd-toscana-api-cluster-20250317";
const RDS_DIMS = [{ Name: "DBClusterIdentifier", Value: RDS_CLUSTER_ID }];

const ECS_CPU_UNITS = 1024;
const ECS_MEM_MB = 2048;

// ============================================================
// Section 2: CLI Args Parser
// ============================================================

function parseArgs(argv) {
  const args = argv.slice(2);
  const opts = {
    mode: "weekly",
    start: null,
    end: null,
    period: 3600,
    piPeriod: null,
    output: null,
    noFetch: false,
  };
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case "--mode":
        opts.mode = args[++i];
        break;
      case "--start":
        opts.start = args[++i];
        break;
      case "--end":
        opts.end = args[++i];
        break;
      case "--period":
        opts.period = parseInt(args[++i], 10);
        break;
      case "--pi-period":
        opts.piPeriod = parseInt(args[++i], 10);
        break;
      case "--output":
        opts.output = args[++i];
        break;
      case "--no-fetch":
        opts.noFetch = true;
        break;
    }
  }
  // Default dates
  if (!opts.start || !opts.end) {
    if (opts.mode === "pi") {
      const now = new Date();
      if (!opts.end) opts.end = toUTCString(now);
      if (!opts.start) opts.start = toUTCString(new Date(now.getTime() - 24 * 60 * 60 * 1000));
    } else {
      const midnightUTC = jstMidnightToUTC(new Date());
      if (!opts.end) opts.end = toUTCString(midnightUTC);
      if (!opts.start) opts.start = toUTCString(new Date(midnightUTC.getTime() - 7 * 24 * 60 * 60 * 1000));
    }
  }
  if (opts.piPeriod == null) opts.piPeriod = opts.mode === "pi" ? 300 : 3600;
  if (!opts.output) {
    const m = { weekly: "report.md", pi: "pi_report.md", cw: "cw_report.md" };
    opts.output = `/tmp/cw_report/${m[opts.mode] || "report.md"}`;
  }
  return opts;
}

function toUTCString(d) {
  return d.toISOString().replace(/\.\d{3}Z$/, "Z");
}

function jstMidnightToUTC(now) {
  const jst = new Date(now.getTime() + JST_OFFSET);
  const midnight = new Date(Date.UTC(jst.getUTCFullYear(), jst.getUTCMonth(), jst.getUTCDate()));
  return new Date(midnight.getTime() - JST_OFFSET);
}

// ============================================================
// Section 3: JSON Cache Helpers
// ============================================================

function saveJson(name, data) {
  mkdirSync(JSON_DIR, { recursive: true });
  writeFileSync(`${JSON_DIR}/${name}`, JSON.stringify(data, null, 2), "utf-8");
}

function loadJson(name) {
  const p = `${JSON_DIR}/${name}`;
  if (!existsSync(p)) return null;
  return JSON.parse(readFileSync(p, "utf-8"));
}

// ============================================================
// Section 4: AWS CLI Execution Layer
// ============================================================

async function awsCmd(service, subcmd, args, { region = REGION, maxBuffer = 10 * 1024 * 1024 } = {}) {
  const cmdArgs = [service, subcmd, "--profile", PROFILE, "--region", region, "--output", "json", ...args];
  try {
    const { stdout } = await execFileAsync("aws", cmdArgs, { maxBuffer });
    return JSON.parse(stdout);
  } catch (err) {
    console.error(`AWS CLI error: aws ${service} ${subcmd} (region=${region})`);
    console.error(err.stderr || err.message);
    return null;
  }
}

function cwMetricQuery(id, ns, name, dims, period, stat) {
  return {
    Id: id,
    MetricStat: {
      Metric: { Namespace: ns, MetricName: name, Dimensions: dims },
      Period: period,
      Stat: stat,
    },
  };
}

async function cwGetMetricData(queries, start, end, region = REGION) {
  return awsCmd(
    "cloudwatch",
    "get-metric-data",
    ["--start-time", start, "--end-time", end, "--metric-data-queries", JSON.stringify(queries)],
    { region },
  );
}

async function piGetMetrics(dbiId, queries, start, end, period) {
  return awsCmd("pi", "get-resource-metrics", [
    "--service-type",
    "RDS",
    "--identifier",
    dbiId,
    "--start-time",
    start,
    "--end-time",
    end,
    "--period-in-seconds",
    String(period),
    "--metric-queries",
    JSON.stringify(queries),
  ]);
}

async function piDescribeKeys(dbiId, metric, groupBy, start, end) {
  return awsCmd("pi", "describe-dimension-keys", [
    "--service-type",
    "RDS",
    "--identifier",
    dbiId,
    "--start-time",
    start,
    "--end-time",
    end,
    "--metric",
    metric,
    "--group-by",
    JSON.stringify(groupBy),
  ]);
}

async function resolveDbiId(noFetch) {
  if (noFetch) {
    const cached = loadJson("rds_dbi_info.json");
    if (cached) return cached;
    throw new Error("rds_dbi_info.json not found. Run without --no-fetch first.");
  }
  const resp = await awsCmd("rds", "describe-db-clusters", []);
  if (!resp) throw new Error("Failed to describe DB clusters");
  const cluster = resp.DBClusters.find((c) => c.DBClusterIdentifier.startsWith(RDS_CLUSTER_PREFIX));
  if (!cluster) throw new Error(`Cluster with prefix '${RDS_CLUSTER_PREFIX}' not found`);
  const writer = cluster.DBClusterMembers.find((m) => m.IsClusterWriter);
  if (!writer) throw new Error(`Writer not found in cluster '${cluster.DBClusterIdentifier}'`);
  const instResp = await awsCmd("rds", "describe-db-instances", [
    "--db-instance-identifier",
    writer.DBInstanceIdentifier,
  ]);
  if (!instResp) throw new Error(`Failed to describe instance '${writer.DBInstanceIdentifier}'`);
  const result = {
    clusterId: cluster.DBClusterIdentifier,
    instanceId: writer.DBInstanceIdentifier,
    dbiResourceId: instResp.DBInstances[0].DbiResourceId,
  };
  saveJson("rds_dbi_info.json", result);
  return result;
}

// ============================================================
// Section 5: Data Fetching
// ============================================================

async function fetchCW(name, queries, opts, region = REGION) {
  const file = `cw_${name}.json`;
  if (opts.noFetch) return loadJson(file);
  const raw = await cwGetMetricData(queries, opts.start, opts.end, region);
  if (raw) saveJson(file, raw);
  return raw;
}

async function fetchCloudFront(opts) {
  const p = opts.period;
  return fetchCW(
    "cf",
    [
      cwMetricQuery("requests", "AWS/CloudFront", "Requests", CF_DIMS, p, "Sum"),
      cwMetricQuery("err4xx", "AWS/CloudFront", "4xxErrorRate", CF_DIMS, p, "Average"),
      cwMetricQuery("err5xx", "AWS/CloudFront", "5xxErrorRate", CF_DIMS, p, "Average"),
    ],
    opts,
    REGION_CF,
  );
}

async function fetchALB(opts) {
  const p = opts.period;
  const ns = "AWS/ApplicationELB";
  return fetchCW(
    "alb",
    [
      cwMetricQuery("req", ns, "RequestCount", ALB_DIMS, p, "Sum"),
      cwMetricQuery("h2xx", ns, "HTTPCode_Target_2XX_Count", ALB_DIMS, p, "Sum"),
      cwMetricQuery("h4xx", ns, "HTTPCode_Target_4XX_Count", ALB_DIMS, p, "Sum"),
      cwMetricQuery("h5xx", ns, "HTTPCode_Target_5XX_Count", ALB_DIMS, p, "Sum"),
      cwMetricQuery("rt_avg", ns, "TargetResponseTime", ALB_DIMS, p, "Average"),
      cwMetricQuery("rt_max", ns, "TargetResponseTime", ALB_DIMS, p, "Maximum"),
    ],
    opts,
  );
}

async function fetchECS(opts) {
  const p = opts.period;
  const ns = "ECS/ContainerInsights";
  return fetchCW(
    "ecs",
    [
      cwMetricQuery("cpu_avg", ns, "CpuUtilized", ECS_DIMS, p, "Average"),
      cwMetricQuery("cpu_max", ns, "CpuUtilized", ECS_DIMS, p, "Maximum"),
      cwMetricQuery("mem_avg", ns, "MemoryUtilized", ECS_DIMS, p, "Average"),
      cwMetricQuery("mem_max", ns, "MemoryUtilized", ECS_DIMS, p, "Maximum"),
      cwMetricQuery("net_rx_avg", ns, "NetworkRxBytes", ECS_DIMS, p, "Average"),
      cwMetricQuery("net_rx_max", ns, "NetworkRxBytes", ECS_DIMS, p, "Maximum"),
      cwMetricQuery("net_tx_avg", ns, "NetworkTxBytes", ECS_DIMS, p, "Average"),
      cwMetricQuery("net_tx_max", ns, "NetworkTxBytes", ECS_DIMS, p, "Maximum"),
      cwMetricQuery("stor_r_avg", ns, "StorageReadBytes", ECS_DIMS, p, "Average"),
      cwMetricQuery("stor_r_max", ns, "StorageReadBytes", ECS_DIMS, p, "Maximum"),
      cwMetricQuery("stor_w_avg", ns, "StorageWriteBytes", ECS_DIMS, p, "Average"),
      cwMetricQuery("stor_w_max", ns, "StorageWriteBytes", ECS_DIMS, p, "Maximum"),
    ],
    opts,
  );
}

async function fetchRDS(opts) {
  const p = opts.period;
  const ns = "AWS/RDS";
  return fetchCW(
    "rds",
    [
      cwMetricQuery("cpu_avg", ns, "CPUUtilization", RDS_DIMS, p, "Average"),
      cwMetricQuery("cpu_max", ns, "CPUUtilization", RDS_DIMS, p, "Maximum"),
      cwMetricQuery("freemem", ns, "FreeableMemory", RDS_DIMS, p, "Average"),
      cwMetricQuery("conn", ns, "DatabaseConnections", RDS_DIMS, p, "Average"),
      cwMetricQuery("cache", ns, "BufferCacheHitRatio", RDS_DIMS, p, "Average"),
      cwMetricQuery("riops", ns, "ReadIOPS", RDS_DIMS, p, "Average"),
      cwMetricQuery("wiops", ns, "WriteIOPS", RDS_DIMS, p, "Average"),
      cwMetricQuery("clat", ns, "CommitLatency", RDS_DIMS, p, "Average"),
      cwMetricQuery("deadlocks", ns, "Deadlocks", RDS_DIMS, p, "Sum"),
    ],
    opts,
  );
}

// --- PI ---

const PI_QUERIES = [
  { name: "db_load", q: [{ Metric: "db.load.avg" }] },
  { name: "wait_events", q: [{ Metric: "db.load.avg", GroupBy: { Group: "db.wait_event", Limit: 10 } }] },
  { name: "top_sql", q: [{ Metric: "db.load.avg", GroupBy: { Group: "db.sql", Limit: 10 } }] },
  { name: "top_users", q: [{ Metric: "db.load.avg", GroupBy: { Group: "db.user", Limit: 10 } }] },
  {
    name: "os_cpu",
    q: [
      { Metric: "os.cpuUtilization.user.avg" },
      { Metric: "os.cpuUtilization.system.avg" },
      { Metric: "os.cpuUtilization.wait.avg" },
      { Metric: "os.cpuUtilization.idle.avg" },
    ],
  },
  {
    name: "transactions",
    q: [{ Metric: "db.Transactions.xact_commit.avg" }, { Metric: "db.Transactions.xact_rollback.avg" }],
  },
  {
    name: "tuples",
    q: [
      { Metric: "db.SQL.tup_returned.avg" },
      { Metric: "db.SQL.tup_fetched.avg" },
      { Metric: "db.SQL.tup_inserted.avg" },
      { Metric: "db.SQL.tup_updated.avg" },
      { Metric: "db.SQL.tup_deleted.avg" },
    ],
  },
  { name: "temp_bytes", q: [{ Metric: "db.Temp.temp_bytes.avg" }, { Metric: "db.Temp.temp_files.avg" }] },
  {
    name: "session_state",
    q: [
      { Metric: "db.Transactions.active_transactions.avg" },
      { Metric: "db.Transactions.blocked_transactions.avg" },
      { Metric: "db.Transactions.max_used_xact_ids.avg" },
      { Metric: "db.state.active_count.avg" },
      { Metric: "db.state.idle_count.avg" },
      { Metric: "db.state.idle_in_transaction_count.avg" },
      { Metric: "db.state.idle_in_transaction_max_time.avg" },
    ],
  },
  {
    name: "os_memory",
    q: [
      { Metric: "os.memory.total.avg" },
      { Metric: "os.memory.free.avg" },
      { Metric: "os.memory.active.avg" },
      { Metric: "os.swap.in.avg" },
      { Metric: "os.swap.out.avg" },
    ],
  },
  {
    name: "aurora_storage_io",
    q: [
      { Metric: "os.diskIO.auroraStorage.diskQueueDepth.avg" },
      { Metric: "os.diskIO.auroraStorage.readLatency.avg" },
      { Metric: "os.diskIO.auroraStorage.writeLatency.avg" },
    ],
  },
  {
    name: "connections",
    q: [
      { Metric: "db.User.numbackends.avg" },
      { Metric: "db.User.max_connections.avg" },
      { Metric: "db.Concurrency.deadlocks.avg" },
    ],
  },
  {
    name: "cache_io",
    q: [
      { Metric: "db.Cache.blks_hit.avg" },
      { Metric: "db.IO.blks_read.avg" },
      { Metric: "db.SQL.total_query_time.avg" },
    ],
  },
  {
    name: "checkpoints",
    q: [
      { Metric: "db.Checkpoint.checkpoints_timed.avg" },
      { Metric: "db.Checkpoint.checkpoints_req.avg" },
      { Metric: "db.Checkpoint.checkpoint_write_latency.avg" },
      { Metric: "db.Checkpoint.checkpoint_sync_latency.avg" },
    ],
  },
];

async function withConcurrency(fns, limit) {
  const results = new Array(fns.length);
  let idx = 0;
  async function worker() {
    while (idx < fns.length) {
      const i = idx++;
      results[i] = await fns[i]();
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, fns.length) }, () => worker()));
  return results;
}

async function fetchAllPI(dbiId, opts) {
  const piData = {};
  const fetchOne = async (name, queries) => {
    const file = `pi_${name}.json`;
    if (opts.noFetch) return loadJson(file);
    console.log(`  PI: ${name}`);
    const result = await piGetMetrics(dbiId, queries, opts.start, opts.end, opts.piPeriod);
    if (result) saveJson(file, result);
    return result;
  };
  const tasks = PI_QUERIES.map((q) => () => fetchOne(q.name, q.q));
  const results = await withConcurrency(tasks, 5);
  PI_QUERIES.forEach((q, i) => {
    piData[q.name] = results[i];
  });

  // SQL details
  const sqlFile = "pi_sql_details.json";
  if (opts.noFetch) {
    piData.sql_details = loadJson(sqlFile);
  } else {
    console.log("  PI: sql_details");
    piData.sql_details = await piDescribeKeys(
      dbiId,
      "db.load.avg",
      { Group: "db.sql", Dimensions: ["db.sql.statement"], Limit: 10 },
      opts.start,
      opts.end,
    );
    if (piData.sql_details) saveJson(sqlFile, piData.sql_details);
  }
  return piData;
}

// ============================================================
// Section 6: Data Transformation
// ============================================================

function toJST(iso) {
  const d = new Date(iso);
  const jst = new Date(d.getTime() + JST_OFFSET);
  const y = jst.getUTCFullYear();
  const mo = String(jst.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(jst.getUTCDate()).padStart(2, "0");
  const hh = String(jst.getUTCHours()).padStart(2, "0");
  const mm = String(jst.getUTCMinutes()).padStart(2, "0");
  const ss = String(jst.getUTCSeconds()).padStart(2, "0");
  return `${y}-${mo}-${dd}T${hh}:${mm}:${ss}+09:00`;
}

function pivotMetricData(raw) {
  if (!raw || !raw.MetricDataResults) return [];
  const byTs = new Map();
  for (const m of raw.MetricDataResults) {
    for (let i = 0; i < (m.Timestamps || []).length; i++) {
      const ts = toJST(m.Timestamps[i]);
      if (!byTs.has(ts)) byTs.set(ts, { timestamp: ts });
      byTs.get(ts)[m.Id] = m.Values[i];
    }
  }
  return [...byTs.values()].sort((a, b) => a.timestamp.localeCompare(b.timestamp));
}

const r2 = (n) => Math.round(n * 100) / 100;
const r1 = (n) => Math.round(n * 10) / 10;

function transformCF(raw) {
  return pivotMetricData(raw).map((r) => ({
    timestamp: r.timestamp,
    requests: Math.round(r.requests || 0),
    "4xx_rate": r.err4xx || 0,
    "5xx_rate": r.err5xx || 0,
  }));
}

function transformALB(raw) {
  return pivotMetricData(raw).map((r) => ({
    timestamp: r.timestamp,
    requests: Math.round(r.req || 0),
    "2xx": Math.round(r.h2xx || 0),
    "4xx": Math.round(r.h4xx || 0),
    "5xx": Math.round(r.h5xx || 0),
    rt_avg_ms: Math.round((r.rt_avg || 0) * 1000),
    rt_max_ms: Math.round((r.rt_max || 0) * 1000),
  }));
}

function transformECS(raw) {
  return pivotMetricData(raw).map((r) => ({
    timestamp: r.timestamp,
    cpu_avg_units: r2(r.cpu_avg || 0),
    cpu_avg_pct: r2(((r.cpu_avg || 0) / ECS_CPU_UNITS) * 100),
    cpu_max_pct: r2(((r.cpu_max || 0) / ECS_CPU_UNITS) * 100),
    mem_avg_mb: r2(r.mem_avg || 0),
    mem_avg_pct: r2(((r.mem_avg || 0) / ECS_MEM_MB) * 100),
    mem_max_mb: r2(r.mem_max || 0),
    net_rx_avg_kb: r2((r.net_rx_avg || 0) / 1024),
    net_rx_max_kb: r2((r.net_rx_max || 0) / 1024),
    net_tx_avg_kb: r2((r.net_tx_avg || 0) / 1024),
    net_tx_max_kb: r2((r.net_tx_max || 0) / 1024),
    stor_r_avg_kb: r2((r.stor_r_avg || 0) / 1024),
    stor_r_max_kb: r2((r.stor_r_max || 0) / 1024),
    stor_w_avg_kb: r2((r.stor_w_avg || 0) / 1024),
    stor_w_max_kb: r2((r.stor_w_max || 0) / 1024),
  }));
}

function transformRDS(raw) {
  return pivotMetricData(raw).map((r) => ({
    timestamp: r.timestamp,
    cpu_avg: r2(r.cpu_avg || 0),
    cpu_max: r2(r.cpu_max || 0),
    freemem_mb: r1((r.freemem || 0) / 1048576),
    connections: r1(r.conn || 0),
    buffer_cache: r2(r.cache || 0),
    read_iops: r1(r.riops || 0),
    write_iops: r1(r.wiops || 0),
    commit_lat_ms: r2((r.clat || 0) / 1000),
    deadlocks: Math.round(r.deadlocks || 0),
  }));
}

// ============================================================
// Section 7: Format Utilities
// ============================================================

const WEEKDAYS = ["日", "月", "火", "水", "木", "金", "土"];
function weekday(d) {
  return WEEKDAYS[d.getDay()];
}

function fmtInt(n) {
  if (n == null || isNaN(n)) return "-";
  return Math.round(n).toLocaleString("en-US");
}

function fmtDec(n, digits = 2) {
  if (n == null || isNaN(n)) return "-";
  return Number(n).toFixed(digits);
}

function fmtDate(d) {
  return `${String(d.getMonth() + 1).padStart(2, "0")}/${String(d.getDate()).padStart(2, "0")}`;
}

function fmtDateFull(d) {
  return `${d.getFullYear()}/${String(d.getMonth() + 1).padStart(2, "0")}/${String(d.getDate()).padStart(2, "0")}`;
}

function fmtHour(h) {
  return `${String(h).padStart(2, "0")}:00`;
}

function fmtPI(n) {
  if (n == null || isNaN(n)) return "-";
  return (Math.round(n * 10000) / 10000).toString();
}

function fmtBytes(bytes) {
  if (bytes == null || isNaN(bytes)) return "-";
  if (bytes >= 1073741824) return fmtDec(bytes / 1073741824) + " GB";
  if (bytes >= 1048576) return fmtDec(bytes / 1048576) + " MB";
  if (bytes >= 1024) return fmtDec(bytes / 1024) + " KB";
  return fmtDec(bytes) + " B";
}

function fmtTsJST(iso) {
  const j = toJST(iso);
  return j.slice(5, 7) + "/" + j.slice(8, 10) + " " + j.slice(11, 16);
}

function alignRow(cols) {
  return "| " + cols.map((c) => (c === "R" ? "-------:" : "------")).join(" | ") + " |";
}

// ============================================================
// Section 8: Date / Aggregation Helpers
// ============================================================

function dateKey(ts) {
  const m = ts.match(/^(\d{4})-(\d{2})-(\d{2})/);
  return m ? `${m[1]}-${m[2]}-${m[3]}` : "";
}

function hourOf(ts) {
  const m = ts.match(/T(\d{2}):/);
  return m ? parseInt(m[1], 10) : 0;
}

function groupByDate(rows) {
  const g = new Map();
  for (const r of rows) {
    const k = dateKey(r.timestamp);
    if (!g.has(k)) g.set(k, []);
    g.get(k).push(r);
  }
  return g;
}

function dateRange(startStr, endStr) {
  const [sy, sm, sd] = startStr.split("-").map(Number);
  const [ey, em, ed] = endStr.split("-").map(Number);
  const s = new Date(sy, sm - 1, sd);
  const e = new Date(ey, em - 1, ed);
  const dates = [];
  for (let d = new Date(s); d <= e; d.setDate(d.getDate() + 1)) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const dd = String(d.getDate()).padStart(2, "0");
    dates.push(`${y}-${m}-${dd}`);
  }
  return dates;
}

function sum(arr) {
  return arr.reduce((a, b) => a + b, 0);
}
function avg(arr) {
  return arr.length === 0 ? 0 : sum(arr) / arr.length;
}
function arrMax(arr) {
  return arr.length === 0 ? 0 : Math.max(...arr);
}

function buildHourlyMap(rows) {
  const m = new Map();
  for (const r of rows) m.set(`${dateKey(r.timestamp)}|${hourOf(r.timestamp)}`, r);
  return m;
}

// ============================================================
// Section 9: CW Report - Layer 1 (Daily Summary)
// ============================================================

function layer1CF(byDate, dates) {
  const L = [];
  L.push("### CloudFront\n");
  L.push("| 日付 | 曜日 | Requests | 4xx率(%) | 5xx率(%) |");
  L.push(alignRow(["L", "L", "R", "R", "R"]));
  let total = 0;
  for (const dk of dates) {
    const rows = byDate.get(dk) || [];
    const d = new Date(dk + "T00:00:00+09:00");
    const req = sum(rows.map((r) => r.requests));
    total += req;
    L.push(
      `| ${fmtDate(d)} | ${weekday(d)} | ${fmtInt(req)} | ${fmtDec(avg(rows.map((r) => r["4xx_rate"])))} | ${fmtDec(avg(rows.map((r) => r["5xx_rate"])))} |`,
    );
  }
  L.push(`| **合計** | | **${fmtInt(total)}** | | |`);
  L.push("");
  return L.join("\n");
}

function layer1ALB(byDate, dates) {
  const L = [];
  L.push("### ALB\n");
  L.push("| 日付 | 曜日 | Requests | 2XX | 4XX | 5XX | RT avg(ms) | RT max(ms) |");
  L.push(alignRow(["L", "L", "R", "R", "R", "R", "R", "R"]));
  let tReq = 0,
    t2 = 0,
    t4 = 0,
    t5 = 0;
  for (const dk of dates) {
    const rows = byDate.get(dk) || [];
    const d = new Date(dk + "T00:00:00+09:00");
    const req = sum(rows.map((r) => r.requests));
    const h2 = sum(rows.map((r) => r["2xx"]));
    const h4 = sum(rows.map((r) => r["4xx"]));
    const h5 = sum(rows.map((r) => r["5xx"]));
    tReq += req;
    t2 += h2;
    t4 += h4;
    t5 += h5;
    L.push(
      `| ${fmtDate(d)} | ${weekday(d)} | ${fmtInt(req)} | ${fmtInt(h2)} | ${fmtInt(h4)} | ${fmtInt(h5)} | ${fmtInt(avg(rows.map((r) => r.rt_avg_ms)))} | ${fmtInt(arrMax(rows.map((r) => r.rt_max_ms)))} |`,
    );
  }
  L.push(`| **合計** | | **${fmtInt(tReq)}** | **${fmtInt(t2)}** | **${fmtInt(t4)}** | **${fmtInt(t5)}** | | |`);
  L.push("");
  return L.join("\n");
}

function layer1ECS(byDate, dates) {
  const L = [];
  L.push("### ECS\n");
  L.push("| 日付 | 曜日 | CPU avg(units) | CPU avg(%) | CPU max(%) | Mem avg(MB) | Mem avg(%) | Mem max(MB) |");
  L.push(alignRow(["L", "L", "R", "R", "R", "R", "R", "R"]));
  for (const dk of dates) {
    const rows = byDate.get(dk) || [];
    const d = new Date(dk + "T00:00:00+09:00");
    L.push(
      `| ${fmtDate(d)} | ${weekday(d)} | ${fmtDec(avg(rows.map((r) => r.cpu_avg_units)))} | ${fmtDec(avg(rows.map((r) => r.cpu_avg_pct)))} | ${fmtDec(arrMax(rows.map((r) => r.cpu_max_pct)))} | ${fmtDec(avg(rows.map((r) => r.mem_avg_mb)), 1)} | ${fmtDec(avg(rows.map((r) => r.mem_avg_pct)))} | ${fmtInt(arrMax(rows.map((r) => r.mem_max_mb)))} |`,
    );
  }
  L.push("");
  return L.join("\n");
}

function layer1ECSNet(byDate, dates) {
  const L = [];
  L.push("### ECS (Network / Storage)\n");
  L.push(
    "| 日付 | 曜日 | NetRx avg(KB) | NetRx max(KB) | NetTx avg(KB) | NetTx max(KB) | StorR avg(KB) | StorW avg(KB) |",
  );
  L.push(alignRow(["L", "L", "R", "R", "R", "R", "R", "R"]));
  for (const dk of dates) {
    const rows = byDate.get(dk) || [];
    const d = new Date(dk + "T00:00:00+09:00");
    L.push(
      `| ${fmtDate(d)} | ${weekday(d)} | ${fmtDec(avg(rows.map((r) => r.net_rx_avg_kb)))} | ${fmtDec(arrMax(rows.map((r) => r.net_rx_max_kb)))} | ${fmtDec(avg(rows.map((r) => r.net_tx_avg_kb)))} | ${fmtDec(arrMax(rows.map((r) => r.net_tx_max_kb)))} | ${fmtDec(avg(rows.map((r) => r.stor_r_avg_kb)))} | ${fmtDec(avg(rows.map((r) => r.stor_w_avg_kb)))} |`,
    );
  }
  L.push("");
  return L.join("\n");
}

function layer1RDS(byDate, dates) {
  const L = [];
  L.push("### RDS\n");
  L.push(
    "| 日付 | 曜日 | CPU avg(%) | CPU max(%) | FreeMem avg(MB) | Connections avg | BufferCache(%) | ReadIOPS | WriteIOPS | CommitLat(ms) | Deadlocks |",
  );
  L.push(alignRow(["L", "L", "R", "R", "R", "R", "R", "R", "R", "R", "R"]));
  for (const dk of dates) {
    const rows = byDate.get(dk) || [];
    const d = new Date(dk + "T00:00:00+09:00");
    L.push(
      `| ${fmtDate(d)} | ${weekday(d)} | ${fmtDec(avg(rows.map((r) => r.cpu_avg)))} | ${fmtDec(arrMax(rows.map((r) => r.cpu_max)))} | ${fmtInt(avg(rows.map((r) => r.freemem_mb)))} | ${fmtDec(avg(rows.map((r) => r.connections)), 1)} | ${fmtInt(avg(rows.map((r) => r.buffer_cache)))} | ${fmtInt(avg(rows.map((r) => r.read_iops)))} | ${fmtDec(avg(rows.map((r) => r.write_iops)))} | ${fmtDec(avg(rows.map((r) => r.commit_lat_ms)))} | ${fmtInt(sum(rows.map((r) => r.deadlocks)))} |`,
    );
  }
  L.push("");
  return L.join("\n");
}

function layer1Summary(cfD, albD, ecsD, rdsD, dates) {
  const L = [];
  L.push("### 総合サマリー\n");
  L.push(
    "| 日付 | 曜日 | CF計 | ALB計 | ALB 2XX | ALB 4XX | ALB 5XX | ECS CPU max(%) | ECS Mem max(MB) | RDS CPU max(%) |",
  );
  L.push(alignRow(["L", "L", "R", "R", "R", "R", "R", "R", "R", "R"]));
  for (const dk of dates) {
    const d = new Date(dk + "T00:00:00+09:00");
    const cf = cfD.get(dk) || [],
      alb = albD.get(dk) || [],
      ecs = ecsD.get(dk) || [],
      rds = rdsD.get(dk) || [];
    L.push(
      `| ${fmtDate(d)} | ${weekday(d)} | ${fmtInt(sum(cf.map((r) => r.requests)))} | ${fmtInt(sum(alb.map((r) => r.requests)))} | ${fmtInt(sum(alb.map((r) => r["2xx"])))} | ${fmtInt(sum(alb.map((r) => r["4xx"])))} | ${fmtInt(sum(alb.map((r) => r["5xx"])))} | ${fmtDec(arrMax(ecs.map((r) => r.cpu_max_pct)))} | ${fmtInt(arrMax(ecs.map((r) => r.mem_max_mb)))} | ${fmtDec(arrMax(rds.map((r) => r.cpu_max)))} |`,
    );
  }
  L.push("");
  return L.join("\n");
}

// ============================================================
// Section 10: CW Report - Layer 2 (Hourly Detail)
// ============================================================

function layer2CF(data, dates) {
  const L = [];
  L.push("### CloudFront\n");
  L.push("| 日付 | 時間(JST) | Requests | 4xx率(%) | 5xx率(%) |");
  L.push(alignRow(["L", "L", "R", "R", "R"]));
  const h = buildHourlyMap(data);
  for (const dk of dates) {
    const d = new Date(dk + "T00:00:00+09:00");
    const ds = fmtDate(d);
    for (let hr = 0; hr < 24; hr++) {
      const r = h.get(`${dk}|${hr}`);
      L.push(
        r
          ? `| ${ds} | ${fmtHour(hr)} | ${fmtInt(r.requests)} | ${fmtDec(r["4xx_rate"])} | ${fmtDec(r["5xx_rate"])} |`
          : `| ${ds} | ${fmtHour(hr)} | - | - | - |`,
      );
    }
  }
  L.push("");
  return L.join("\n");
}

function layer2ALB(data, dates) {
  const L = [];
  L.push("### ALB\n");
  L.push("| 日付 | 時間(JST) | Requests | 2XX | 4XX | 5XX | RT avg(ms) | RT max(ms) |");
  L.push(alignRow(["L", "L", "R", "R", "R", "R", "R", "R"]));
  const h = buildHourlyMap(data);
  for (const dk of dates) {
    const d = new Date(dk + "T00:00:00+09:00");
    const ds = fmtDate(d);
    for (let hr = 0; hr < 24; hr++) {
      const r = h.get(`${dk}|${hr}`);
      L.push(
        r
          ? `| ${ds} | ${fmtHour(hr)} | ${fmtInt(r.requests)} | ${fmtInt(r["2xx"])} | ${fmtInt(r["4xx"])} | ${fmtInt(r["5xx"])} | ${fmtInt(r.rt_avg_ms)} | ${fmtInt(r.rt_max_ms)} |`
          : `| ${ds} | ${fmtHour(hr)} | - | - | - | - | - | - |`,
      );
    }
  }
  L.push("");
  return L.join("\n");
}

function layer2ECS(data, dates) {
  const L = [];
  L.push("### ECS\n");
  L.push("| 日付 | 時間(JST) | CPU avg(units) | CPU avg(%) | CPU max(%) | Mem avg(MB) | Mem avg(%) | Mem max(MB) |");
  L.push(alignRow(["L", "L", "R", "R", "R", "R", "R", "R"]));
  const h = buildHourlyMap(data);
  for (const dk of dates) {
    const d = new Date(dk + "T00:00:00+09:00");
    const ds = fmtDate(d);
    for (let hr = 0; hr < 24; hr++) {
      const r = h.get(`${dk}|${hr}`);
      L.push(
        r
          ? `| ${ds} | ${fmtHour(hr)} | ${fmtDec(r.cpu_avg_units)} | ${fmtDec(r.cpu_avg_pct)} | ${fmtDec(r.cpu_max_pct)} | ${fmtDec(r.mem_avg_mb, 1)} | ${fmtDec(r.mem_avg_pct)} | ${fmtInt(r.mem_max_mb)} |`
          : `| ${ds} | ${fmtHour(hr)} | - | - | - | - | - | - |`,
      );
    }
  }
  L.push("");
  return L.join("\n");
}

function layer2ECSNet(data, dates) {
  const L = [];
  L.push("### ECS (Network / Storage)\n");
  L.push("| 日付 | 時間(JST) | NetRx avg(KB) | NetTx avg(KB) | StorR avg(KB) | StorW avg(KB) |");
  L.push(alignRow(["L", "L", "R", "R", "R", "R"]));
  const h = buildHourlyMap(data);
  for (const dk of dates) {
    const d = new Date(dk + "T00:00:00+09:00");
    const ds = fmtDate(d);
    for (let hr = 0; hr < 24; hr++) {
      const r = h.get(`${dk}|${hr}`);
      L.push(
        r
          ? `| ${ds} | ${fmtHour(hr)} | ${fmtDec(r.net_rx_avg_kb)} | ${fmtDec(r.net_tx_avg_kb)} | ${fmtDec(r.stor_r_avg_kb)} | ${fmtDec(r.stor_w_avg_kb)} |`
          : `| ${ds} | ${fmtHour(hr)} | - | - | - | - |`,
      );
    }
  }
  L.push("");
  return L.join("\n");
}

function layer2RDS(data, dates) {
  const L = [];
  L.push("### RDS\n");
  L.push(
    "| 日付 | 時間(JST) | CPU avg(%) | CPU max(%) | FreeMem avg(MB) | Connections avg | BufferCache(%) | ReadIOPS | WriteIOPS | CommitLat(ms) | Deadlocks |",
  );
  L.push(alignRow(["L", "L", "R", "R", "R", "R", "R", "R", "R", "R", "R"]));
  const h = buildHourlyMap(data);
  for (const dk of dates) {
    const d = new Date(dk + "T00:00:00+09:00");
    const ds = fmtDate(d);
    for (let hr = 0; hr < 24; hr++) {
      const r = h.get(`${dk}|${hr}`);
      L.push(
        r
          ? `| ${ds} | ${fmtHour(hr)} | ${fmtDec(r.cpu_avg)} | ${fmtDec(r.cpu_max)} | ${fmtInt(r.freemem_mb)} | ${fmtDec(r.connections, 1)} | ${fmtInt(r.buffer_cache)} | ${fmtInt(r.read_iops)} | ${fmtDec(r.write_iops)} | ${fmtDec(r.commit_lat_ms)} | ${fmtInt(r.deadlocks)} |`
          : `| ${ds} | ${fmtHour(hr)} | - | - | - | - | - | - | - | - | - |`,
      );
    }
  }
  L.push("");
  return L.join("\n");
}

// ============================================================
// Section 11: CW Report - Layer 3 (Spike Drilldown)
// ============================================================

function layer3Spikes(cfData, albData, ecsData, rdsData, dates) {
  const L = [];
  const albH = buildHourlyMap(albData);
  const ecsH = buildHourlyMap(ecsData);
  const rdsH = buildHourlyMap(rdsData);
  const albByDate = groupByDate(albData);
  const ecsByDate = groupByDate(ecsData);

  const spikes = [];
  for (const dk of dates) {
    const albRows = albByDate.get(dk) || [];
    const ecsRows = ecsByDate.get(dk) || [];
    const albAvgReq = avg(albRows.map((r) => r.requests));
    const ecsCpuMaxPctAvg = avg(ecsRows.map((r) => r.cpu_max_pct));

    for (let h = 0; h < 24; h++) {
      const key = `${dk}|${h}`;
      const aR = albH.get(key),
        eR = ecsH.get(key),
        rR = rdsH.get(key);
      const triggers = [];
      if (eR && ecsCpuMaxPctAvg > 0 && eR.cpu_max_pct >= ecsCpuMaxPctAvg * 3) triggers.push("ECS CPU");
      if (aR && albAvgReq > 0 && aR.requests >= albAvgReq * 2) triggers.push("ALB Requests");
      if (rR && rR.cpu_max >= 20) triggers.push("RDS CPU");
      if (aR && aR["5xx"] >= 1) triggers.push("ALB 5XX");

      const hasNonAlb = triggers.some((t) => t !== "ALB Requests");
      if (triggers.length > 0 && (hasNonAlb || triggers.includes("ALB 5XX"))) {
        const last = spikes.length > 0 ? spikes[spikes.length - 1] : null;
        if (last && last.dk === dk && h <= last.endHour + 2) {
          last.endHour = h;
          for (const t of triggers) if (!last.triggers.includes(t)) last.triggers.push(t);
        } else {
          spikes.push({ dk, startHour: h, endHour: h, triggers });
        }
      }
    }
  }

  if (spikes.length === 0) {
    L.push("検出なし\n");
    return L.join("\n");
  }

  for (const sp of spikes) {
    const d = new Date(sp.dk + "T00:00:00+09:00");
    const fromH = Math.max(0, sp.startHour - 1);
    const toH = Math.min(23, sp.endHour + 1);
    L.push(`### ${fmtDate(d)} スパイク詳細 (${fmtHour(fromH)}-${fmtHour(toH + 1)} JST)\n`);
    L.push("| 時間(JST) | ALB Requests | ALB 5XX | ECS CPU(%) | ECS Mem(MB) | RDS CPU(%) | RDS CommitLat(ms) |");
    L.push(alignRow(["L", "R", "R", "R", "R", "R", "R"]));
    for (let h = fromH; h <= toH; h++) {
      const key = `${sp.dk}|${h}`;
      const a = albH.get(key),
        e = ecsH.get(key),
        r = rdsH.get(key);
      L.push(
        `| ${fmtHour(h)} | ${a ? fmtInt(a.requests) : "-"} | ${a ? fmtInt(a["5xx"]) : "-"} | ${e ? fmtDec(e.cpu_max_pct) : "-"} | ${e ? fmtInt(e.mem_max_mb) : "-"} | ${r ? fmtDec(r.cpu_max) : "-"} | ${r ? fmtDec(r.commit_lat_ms) : "-"} |`,
      );
    }
    L.push("");
  }

  if (!albData.some((r) => r["5xx"] >= 1)) {
    L.push("### ALB 5XX\n");
    L.push("検出なし (全期間 0件)\n");
  }
  return L.join("\n");
}

// ============================================================
// Section 12: PI Report - Layer 4
// ============================================================

function piMetricLabel(metric) {
  const parts = metric.split(".");
  const last = parts[parts.length - 1];
  return ["avg", "sum", "max", "min"].includes(last) ? parts[parts.length - 2] : last;
}

function piSummarizeGroupBy(raw, dimNameKey) {
  if (!raw || !raw.MetricList) return [];
  return raw.MetricList.filter((m) => m.Key.Dimensions && typeof m.Key.Dimensions === "object")
    .map((m) => ({
      name: m.Key.Dimensions[dimNameKey] || "other",
      dims: m.Key.Dimensions,
      total: (m.DataPoints || []).reduce((s, d) => s + (d.Value || 0), 0),
    }))
    .sort((a, b) => b.total - a.total);
}

function piSummarizeMetrics(raw) {
  if (!raw || !raw.MetricList) return [];
  return raw.MetricList.map((m) => {
    const vals = (m.DataPoints || []).map((d) => d.Value || 0);
    return {
      metric: m.Key.Metric,
      label: piMetricLabel(m.Key.Metric),
      avg: vals.length > 0 ? vals.reduce((s, v) => s + v, 0) / vals.length : 0,
      max: vals.length > 0 ? Math.max(...vals) : 0,
      min: vals.length > 0 ? Math.min(...vals) : 0,
      nonzero: vals.filter((v) => v > 0).length,
      total: vals.length,
    };
  });
}

function piDbLoad(data) {
  if (!data || !data.MetricList) return "### DB Load (Average Active Sessions)\n\n_データなし_\n";
  const points = (data.MetricList[0]?.DataPoints || []).sort((a, b) =>
    (a.Timestamp || "").localeCompare(b.Timestamp || ""),
  );
  if (points.length === 0) return "### DB Load (Average Active Sessions)\n\n_データなし_\n";
  const L = ["### DB Load (Average Active Sessions)\n"];
  L.push("| 時間(JST) | DB Load (AAS) |");
  L.push("| ------ | -------: |");
  for (const p of points) {
    L.push(`| ${fmtTsJST(p.Timestamp)} | ${fmtPI(p.Value)} |`);
  }
  L.push("");
  return L.join("\n");
}

function piWaitEvents(data) {
  const items = piSummarizeGroupBy(data, "db.wait_event.name");
  if (items.length === 0) return "### Top Wait Events\n\n_データなし_\n";
  const L = ["### Top Wait Events\n"];
  L.push("| Wait Event | 合計 DB Load |");
  L.push("| ------ | -------: |");
  for (const it of items) L.push(`| ${it.name} | ${fmtPI(it.total)} |`);
  L.push("");
  return L.join("\n");
}

function piTopSQL(data) {
  const items = piSummarizeGroupBy(data, "db.sql.id");
  if (items.length === 0) return "### Top SQL (by DB Load)\n\n_データなし_\n";
  const L = ["### Top SQL (by DB Load)\n"];
  L.push("| # | SQL ID | SQL (先頭80文字) | 合計 DB Load |");
  L.push("| --: | ------ | ------ | -------: |");
  items.forEach((it, i) => {
    const stmt = (it.dims["db.sql.statement"] || "").slice(0, 80);
    const suffix = (it.dims["db.sql.statement"] || "").length > 80 ? "..." : "";
    L.push(`| ${i + 1} | \`${(it.name || "").slice(0, 12)}\` | ${stmt}${suffix} | ${fmtPI(it.total)} |`);
  });
  L.push("");
  return L.join("\n");
}

function piSQLDetails(data) {
  if (!data || !data.Keys || data.Keys.length === 0) return "### SQL 文詳細\n\n_データなし_\n";
  const L = ["### SQL 文詳細\n"];
  data.Keys.forEach((k, i) => {
    L.push(`#### ${i + 1}. DB Load: ${fmtPI(k.Total || 0)}\n`);
    L.push("```sql");
    L.push(k.Dimensions?.["db.sql.statement"] || "N/A");
    L.push("```\n");
  });
  return L.join("\n");
}

function piTopUsers(data) {
  const items = piSummarizeGroupBy(data, "db.user.name");
  if (items.length === 0) return "### Top Users (by DB Load)\n\n_データなし_\n";
  const L = ["### Top Users (by DB Load)\n"];
  L.push("| User | 合計 DB Load |");
  L.push("| ------ | -------: |");
  for (const it of items) L.push(`| ${it.name} | ${fmtPI(it.total)} |`);
  L.push("");
  return L.join("\n");
}

function piOsCpu(data) {
  const items = piSummarizeMetrics(data);
  if (items.length === 0) return "### OS CPU 内訳 (%)\n\n_データなし_\n";
  const L = ["### OS CPU 内訳 (%)\n"];
  L.push("| カテゴリ | 平均(%) |");
  L.push("| ------ | -------: |");
  items.sort((a, b) => b.avg - a.avg);
  for (const it of items) L.push(`| ${it.label} | ${fmtDec(it.avg)} |`);
  L.push("");
  return L.join("\n");
}

function piTransactions(data) {
  const items = piSummarizeMetrics(data);
  if (items.length === 0) return "### トランザクション統計 (per sec)\n\n_データなし_\n";
  const L = ["### トランザクション統計 (per sec)\n"];
  L.push("| 種別 | 平均(/sec) | 最大(/sec) |");
  L.push("| ------ | -------: | -------: |");
  for (const it of items) {
    const label = it.label.replace(/^xact_/, "");
    L.push(`| ${label} | ${fmtDec(it.avg)} | ${fmtDec(it.max)} |`);
  }
  L.push("");
  return L.join("\n");
}

function piTuples(data) {
  const items = piSummarizeMetrics(data);
  if (items.length === 0) return "### Tuple 操作統計 (per sec)\n\n_データなし_\n";
  const L = ["### Tuple 操作統計 (per sec)\n"];
  L.push("| 操作 | 平均(/sec) | 最大(/sec) |");
  L.push("| ------ | -------: | -------: |");
  for (const it of items) {
    const label = it.label.replace(/^tup_/, "");
    L.push(`| ${label} | ${fmtDec(it.avg)} | ${fmtDec(it.max)} |`);
  }
  L.push("");
  return L.join("\n");
}

function piTempBytes(data) {
  const items = piSummarizeMetrics(data);
  if (items.length === 0) return "### Temp (ディスクスピル)\n\n_データなし_\n";
  const L = ["### Temp (ディスクスピル)\n"];
  L.push("| 指標 | 平均 | 最大 | 非ゼロ回数 |");
  L.push("| ------ | -------: | -------: | -------: |");
  for (const it of items) {
    if (it.label === "temp_bytes") {
      L.push(`| temp_bytes | ${fmtBytes(it.avg)} | ${fmtBytes(it.max)} | ${it.nonzero}/${it.total} |`);
    } else {
      L.push(`| temp_files | ${fmtDec(it.avg)}/sec | ${fmtDec(it.max)}/sec | ${it.nonzero}/${it.total} |`);
    }
  }
  L.push("");
  return L.join("\n");
}

function piSessionState(data) {
  const items = piSummarizeMetrics(data);
  if (items.length === 0) return "### セッション・ロック状態\n\n_データなし_\n";
  const L = ["### セッション・ロック状態\n"];
  L.push("| 指標 | 平均 | 最大 |");
  L.push("| ------ | -------: | -------: |");
  for (const it of items) L.push(`| ${it.label} | ${fmtPI(it.avg)} | ${fmtPI(it.max)} |`);
  L.push("");
  return L.join("\n");
}

function piOsMemory(data) {
  const items = piSummarizeMetrics(data);
  if (items.length === 0) return "### OS メモリ & Swap\n\n_データなし_\n";
  const L = ["### OS メモリ & Swap\n"];
  L.push("| 指標 | 平均 | 最小 | 最大 | 単位 |");
  L.push("| ------ | -------: | -------: | -------: | ------ |");
  for (const it of items) {
    const isMem = it.metric.startsWith("os.memory");
    if (isMem) {
      const toMB = (v) => fmtDec(v / 1024);
      L.push(`| ${it.label} | ${toMB(it.avg)} | ${toMB(it.min)} | ${toMB(it.max)} | MB |`);
    } else {
      L.push(`| swap.${it.label} | ${fmtDec(it.avg)} | ${fmtDec(it.min)} | ${fmtDec(it.max)} | KB |`);
    }
  }
  L.push("");
  return L.join("\n");
}

function piAuroraIO(data) {
  const items = piSummarizeMetrics(data);
  if (items.length === 0) return "### Aurora Storage I/O\n\n_データなし_\n";
  const L = ["### Aurora Storage I/O\n"];
  L.push("| 指標 | 平均 | 最大 | 単位 |");
  L.push("| ------ | -------: | -------: | ------ |");
  for (const it of items) {
    const unit = it.label === "diskQueueDepth" ? "requests" : "ms";
    L.push(`| ${it.label} | ${fmtPI(it.avg)} | ${fmtPI(it.max)} | ${unit} |`);
  }
  L.push("");
  return L.join("\n");
}

function piConnections(data) {
  const items = piSummarizeMetrics(data);
  if (items.length === 0) return "### コネクション & デッドロック\n\n_データなし_\n";
  const L = ["### コネクション & デッドロック\n"];
  L.push("| 指標 | 平均 | 最小 | 最大 |");
  L.push("| ------ | -------: | -------: | -------: |");
  for (const it of items) L.push(`| ${it.label} | ${fmtDec(it.avg)} | ${fmtDec(it.min)} | ${fmtDec(it.max)} |`);
  L.push("");
  return L.join("\n");
}

function piCacheIO(data) {
  const items = piSummarizeMetrics(data);
  if (items.length === 0) return "### キャッシュ & I/O\n\n_データなし_\n";
  const L = ["### キャッシュ & I/O\n"];
  L.push("| 指標 | 平均(/sec) | 最大(/sec) |");
  L.push("| ------ | -------: | -------: |");
  for (const it of items) L.push(`| ${it.label} | ${fmtDec(it.avg)} | ${fmtDec(it.max)} |`);
  const hit = items.find((i) => i.label === "blks_hit");
  const read = items.find((i) => i.label === "blks_read");
  if (hit && read && hit.avg + read.avg > 0) {
    const ratio = ((hit.avg / (hit.avg + read.avg)) * 100).toFixed(2);
    L.push(`| **cache_hit_ratio** | **${ratio}%** | - |`);
  }
  L.push("");
  return L.join("\n");
}

function piCheckpoints(data) {
  const items = piSummarizeMetrics(data);
  if (items.length === 0) return "### チェックポイント統計\n\n_データなし_\n";
  const L = ["### チェックポイント統計\n"];
  L.push("| 指標 | 平均 | 最大 |");
  L.push("| ------ | -------: | -------: |");
  for (const it of items) L.push(`| ${it.label} | ${fmtPI(it.avg)} | ${fmtPI(it.max)} |`);
  L.push("");
  return L.join("\n");
}

function buildPIReport(piData, dbiInfo) {
  const S = [];
  S.push(piDbLoad(piData.db_load));
  S.push(piWaitEvents(piData.wait_events));
  S.push(piTopSQL(piData.top_sql));
  S.push(piSQLDetails(piData.sql_details));
  S.push(piTopUsers(piData.top_users));
  S.push(piOsCpu(piData.os_cpu));
  S.push(piTransactions(piData.transactions));
  S.push(piTuples(piData.tuples));
  S.push(piTempBytes(piData.temp_bytes));
  S.push(piSessionState(piData.session_state));
  S.push(piOsMemory(piData.os_memory));
  S.push(piAuroraIO(piData.aurora_storage_io));
  S.push(piConnections(piData.connections));
  S.push(piCacheIO(piData.cache_io));
  S.push(piCheckpoints(piData.checkpoints));
  return S.join("\n");
}

// ============================================================
// Section 13: Report Assembly
// ============================================================

function buildReport(cwData, piData, dbiInfo, opts) {
  const S = [];

  if (opts.mode === "pi") {
    // PI-only header
    const startJST = fmtTsJST(opts.start);
    const endJST = fmtTsJST(opts.end);
    const today = new Date();
    const created = fmtDateFull(today);
    S.push(`# Performance Insights レポート\n`);
    S.push(`**期間**: ${startJST} - ${endJST} (JST)`);
    S.push(`**作成日**: ${created}`);
    if (dbiInfo) S.push(`**インスタンス**: ${dbiInfo.instanceId} (${dbiInfo.clusterId})`);
    S.push(`**取得間隔**: ${opts.piPeriod}秒\n`);
    S.push("---\n");
    if (piData) S.push(buildPIReport(piData, dbiInfo));
    S.push("---\n");
  } else {
    // CW header (weekly / cw)
    const allData = [...(cwData?.cf || []), ...(cwData?.alb || []), ...(cwData?.ecs || []), ...(cwData?.rds || [])];
    const allDateKeys = [...new Set(allData.map((r) => dateKey(r.timestamp)))].sort();
    const startKey = allDateKeys[0] || "";
    const endKey = allDateKeys[allDateKeys.length - 1] || "";
    const dates = dateRange(startKey, endKey);

    const startDate = new Date(startKey + "T00:00:00+09:00");
    const endDate = new Date(endKey + "T00:00:00+09:00");
    const today = new Date();
    const created = fmtDateFull(today);

    S.push(`# 本番環境メトリクスレポート\n`);
    S.push(
      `**期間**: ${fmtDateFull(startDate)} (${weekday(startDate)}) - ${fmtDateFull(endDate)} (${weekday(endDate)})`,
    );
    S.push(`**作成日**: ${created}`);
    S.push(`**プロファイル**: ${PROFILE}`);
    S.push(
      `**インフラ構成**: ECS Fargate (1 vCPU / 2048 MB) × 1 task, Aurora PostgreSQL db.t4g.large (2 vCPU / 8 GB)\n`,
    );
    S.push("---\n");

    if (cwData) {
      const cfD = groupByDate(cwData.cf);
      const albD = groupByDate(cwData.alb);
      const ecsD = groupByDate(cwData.ecs);
      const rdsD = groupByDate(cwData.rds);

      // Layer 1
      S.push("## Layer 1: 日次サマリー\n");
      S.push(layer1CF(cfD, dates));
      S.push(layer1ALB(albD, dates));
      S.push(layer1ECS(ecsD, dates));
      S.push(layer1ECSNet(ecsD, dates));
      S.push(layer1RDS(rdsD, dates));
      S.push(layer1Summary(cfD, albD, ecsD, rdsD, dates));
      S.push("---\n");

      // Layer 2
      S.push("## Layer 2: 時間帯別詳細\n");
      S.push(layer2CF(cwData.cf, dates));
      S.push(layer2ALB(cwData.alb, dates));
      S.push(layer2ECS(cwData.ecs, dates));
      S.push(layer2ECSNet(cwData.ecs, dates));
      S.push(layer2RDS(cwData.rds, dates));
      S.push("---\n");

      // Layer 3
      S.push("## Layer 3: スパイクドリルダウン\n");
      S.push(layer3Spikes(cwData.cf, cwData.alb, cwData.ecs, cwData.rds, dates));
      S.push("---\n");
    }

    // Layer 4 (PI) - weekly mode only
    if (opts.mode === "weekly" && piData) {
      S.push("## Layer 4: Performance Insights\n");
      if (dbiInfo)
        S.push(`**インスタンス**: ${dbiInfo.instanceId} (${dbiInfo.clusterId}) / 取得間隔: ${opts.piPeriod}秒\n`);
      S.push(buildPIReport(piData, dbiInfo));
      S.push("---\n");
    }
  }

  // Findings placeholder
  S.push(`## 主な所見\n`);
  S.push(`<!-- エージェントがデータに基づいて記述する -->\n`);
  S.push(`## 推奨アクション\n`);
  S.push(`<!-- エージェントがデータに基づいて記述する -->\n`);

  return S.join("\n");
}

// ============================================================
// Section 14: main
// ============================================================

async function main() {
  const opts = parseArgs(process.argv);
  console.log(`Mode: ${opts.mode}`);
  console.log(`Period: ${opts.start} → ${opts.end}`);
  console.log(`CW period: ${opts.period}s, PI period: ${opts.piPeriod}s`);
  console.log(`Output: ${opts.output}`);
  if (opts.noFetch) console.log("(--no-fetch: using cached JSON)");

  let cwData = null;
  let piData = null;
  let dbiInfo = null;

  if (opts.mode === "weekly") {
    // Phase 1: CW + DBI resolution in parallel
    console.log("\nPhase 1: CW metrics + DBI resolution...");
    const [cfRaw, albRaw, ecsRaw, rdsRaw, dbi] = await Promise.all([
      fetchCloudFront(opts),
      fetchALB(opts),
      fetchECS(opts),
      fetchRDS(opts),
      resolveDbiId(opts.noFetch).catch((e) => {
        console.error(`  DBI: ${e.message}`);
        return null;
      }),
    ]);
    cwData = {
      cf: transformCF(cfRaw),
      alb: transformALB(albRaw),
      ecs: transformECS(ecsRaw),
      rds: transformRDS(rdsRaw),
    };
    dbiInfo = dbi;
    console.log("  CW done.");

    // Phase 2: PI (if DBI resolved)
    if (dbiInfo) {
      console.log("\nPhase 2: PI metrics...");
      piData = await fetchAllPI(dbiInfo.dbiResourceId, opts);
      console.log("  PI done.");
    } else {
      console.log("\n  PI skipped (DBI resolution failed).");
    }
  } else if (opts.mode === "cw") {
    console.log("\nFetching CW metrics...");
    const [cfRaw, albRaw, ecsRaw, rdsRaw] = await Promise.all([
      fetchCloudFront(opts),
      fetchALB(opts),
      fetchECS(opts),
      fetchRDS(opts),
    ]);
    cwData = {
      cf: transformCF(cfRaw),
      alb: transformALB(albRaw),
      ecs: transformECS(ecsRaw),
      rds: transformRDS(rdsRaw),
    };
    console.log("  Done.");
  } else if (opts.mode === "pi") {
    console.log("\nResolving DBI...");
    dbiInfo = await resolveDbiId(opts.noFetch);
    console.log(`  ${dbiInfo.instanceId} (${dbiInfo.dbiResourceId})`);
    console.log("\nFetching PI metrics...");
    piData = await fetchAllPI(dbiInfo.dbiResourceId, opts);
    console.log("  Done.");
  }

  console.log("\nGenerating report...");
  const report = buildReport(cwData, piData, dbiInfo, opts);
  mkdirSync(dirname(opts.output), { recursive: true });
  writeFileSync(opts.output, report, "utf-8");
  console.log(`Report written to: ${opts.output}`);
}

main().catch((e) => {
  console.error(`FATAL: ${e.message}`);
  process.exit(1);
});
