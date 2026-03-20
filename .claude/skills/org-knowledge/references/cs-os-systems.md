# OS・システムプログラミング

## OS の3本柱（Arpaci-Dusseau『OSTEP』ベース）

### 1. 仮想化（Virtualization）

#### プロセス

```
プロセス = 実行中のプログラム

【プロセスの構成要素】
- アドレス空間（コード、データ、ヒープ、スタック）
- レジスタ（PC, SP, 汎用レジスタ）
- オープンファイルディスクリプタ
- PID、UID、環境変数

【プロセス状態】
New → Ready → Running → Blocked → Ready → ... → Terminated

【fork + exec モデル（UNIX）】
fork(): 親プロセスのコピーを作成（COW: Copy-on-Write）
exec(): 新しいプログラムに置き換え
wait(): 子プロセスの終了を待つ
→ シェルはこのモデルでコマンドを実行

【プロセス間通信（IPC）】
パイプ（pipe）: 一方向のバイトストリーム
名前付きパイプ（FIFO）: ファイルシステム上のパイプ
UNIXドメインソケット: ローカル通信（TCP/UDPより高速）
共有メモリ: mmap / shmget（最高速だが同期が必要）
メッセージキュー: msgget / mq_open
シグナル: 非同期通知（SIGTERM, SIGKILL, SIGUSR1等）
```

#### スケジューリング

| アルゴリズム | 特徴 |
|-------------|------|
| FIFO | 単純だがconvoy effect |
| SJF（最短ジョブ優先） | 最適だが実行時間が未知 |
| RR（ラウンドロビン） | 公平、タイムスライスで切替 |
| MLFQ（多段フィードバックキュー） | 優先度を動的に調整 |
| CFS（Completely Fair Scheduler） | Linux標準。仮想実行時間で公平配分 |

#### メモリ管理

```
【仮想メモリ】
各プロセスに独立したアドレス空間を提供
仮想アドレス → ページテーブル → 物理アドレス

【ページング】
ページサイズ: 通常4KB（Huge Page: 2MB/1GB）
TLB（Translation Lookaside Buffer）: ページテーブルのキャッシュ
  TLBミス → ページテーブルウォーク（コストが高い）

【ページ置換】
LRU: 最近最も使われていないページを追い出す
Clock: LRUの近似（参照ビットを巡回チェック）

【メモリマップドI/O（mmap）】
ファイルを仮想アドレス空間にマッピング
→ read/write syscall なしでファイルアクセス
→ DB（SQLite等）やログファイルの効率的な読み書き
```

### 2. 並行性（Concurrency）

#### スレッド

```
スレッド = プロセス内の実行単位（アドレス空間を共有）

【スレッドモデル】
1:1（ネイティブスレッド）: OSスレッド1つにユーザースレッド1つ（Linux pthread）
M:N（グリーンスレッド）: ユーザー空間で多数のスレッドをOSスレッドにマッピング（Go goroutine）
イベントループ: シングルスレッド + 非同期I/O（Node.js, Python asyncio）
```

#### 同期プリミティブ

| プリミティブ | 用途 | 注意 |
|-------------|------|------|
| Mutex | 排他制御 | デッドロック、優先度逆転 |
| Spinlock | 短時間の排他 | CPU消費（忙しい待ち） |
| Semaphore | カウンタベースの同期 | 生産者消費者パターン |
| Condition Variable | 条件が成立するまで待機 | spurious wakeup に注意 |
| Read-Write Lock | 読み取り並行、書込み排他 | writer starvation |
| Futex | Linux の効率的な待機機構 | カーネル/ユーザ空間協調 |

#### 並行性の問題

```
【デッドロックの4条件（全て成立すると発生）】
1. 相互排除: リソースは一度に1つのスレッドのみ
2. 保持と待機: 保持しながら他を要求
3. 横取り不可: 強制解放できない
4. 循環待ち: A→B→C→A の依存

【防止策】
ロック順序を固定（循環待ちを排除）
タイムアウト付きロック
デッドロック検出（依存グラフ）

【データ競合（Race Condition）】
複数スレッドが共有データに同時アクセスし、少なくとも1つが書込み
→ 結果が実行順序に依存（非決定的）
→ mutex / atomic 操作で保護
```

#### Lock-free / Wait-free

```
CAS（Compare-And-Swap）: ハードウェア提供のアトミック操作
  if (*addr == expected) { *addr = desired; return true; }
  else { return false; }

Lock-free: 少なくとも1つのスレッドが進行を保証
Wait-free: 全てのスレッドが有限ステップで完了を保証
→ 高性能キュー、カウンタ、参照カウントに使用
```

### 3. 永続性（Persistence）

#### ファイルシステム

```
【構造】
スーパーブロック: FS全体のメタデータ
inode: ファイルのメタデータ（サイズ、権限、データブロックへのポインタ）
データブロック: ファイルの実データ
ディレクトリ: ファイル名→inode番号のマッピング

【主要なFS】
ext4: Linux標準。ジャーナリング、エクステント
XFS: 大規模ファイル/FS向け
Btrfs: COW、スナップショット、チェックサム
ZFS: エンタープライズ級、RAID統合、圧縮

【ジャーナリング】
データ書込み前にジャーナル（ログ）に記録
クラッシュ時にジャーナルからリカバリ
→ DBのWALと同じ考え方
```

#### I/O

```
【I/Oモデル】
ブロッキングI/O: read() が完了するまで待機
ノンブロッキングI/O: 即座に返る（EAGAIN/EWOULDBLOCK）
I/O多重化: select / poll / epoll で複数fdを監視
非同期I/O: io_uring（Linux 5.1+）、IOCP（Windows）

【epoll（Linux）】
イベント駆動I/O多重化
  epoll_create → epoll_ctl(ADD) → epoll_wait
Edge-triggered: 状態変化時のみ通知（高性能）
Level-triggered: 条件が成立している間通知（安全）
→ nginx, Node.js, Tokio(Rust) の基盤

【io_uring】
カーネルとユーザ空間の共有リングバッファでI/O要求をやり取り
→ syscall オーバーヘッドを大幅削減
→ 次世代の非同期I/O基盤
```

## Linuxシステムプログラミング（Kerrisk『TLPI』ベース）

### プロセス管理

```
fork()  → 子プロセス作成
exec*() → プログラム実行
wait*() → 子プロセス待機
kill()  → シグナル送信
clone() → スレッド/名前空間付きプロセス作成

【デーモン化】
1. fork() → 親を終了
2. setsid() → 新セッション
3. fork() → 制御端末を完全に切り離す
4. chdir("/") → ルートに移動
5. umask(0) → ファイル作成マスクをクリア
6. close(0,1,2) → 標準入出力を閉じる
→ 現代は systemd が管理するので手動デーモン化は減少
```

### ファイルI/O

```
【基本syscall】
open(path, flags, mode) → fd
read(fd, buf, count) → bytes_read
write(fd, buf, count) → bytes_written
close(fd)
lseek(fd, offset, whence) → 位置変更

【重要なフラグ】
O_CREAT: ファイル作成
O_APPEND: 末尾追記（アトミック）
O_SYNC: 同期書込み（fsync不要だが遅い）
O_DIRECT: カーネルバッファキャッシュをバイパス
O_NONBLOCK: ノンブロッキング

【fsync / fdatasync】
fsync(fd): データ + メタデータをディスクに永続化
fdatasync(fd): データのみ永続化（メタデータは不完全でも可）
→ DBではコミット時に必須
```

### シグナル

```
【重要なシグナル】
SIGTERM (15): 終了要求（ graceful shutdown ）
SIGKILL (9): 即座に終了（キャッチ不可）
SIGINT (2): Ctrl+C
SIGHUP (1): 端末切断 / 設定再読み込み
SIGCHLD: 子プロセス状態変化
SIGUSR1/2: ユーザ定義
SIGPIPE: 壊れたパイプへの書込み → デフォルトで終了
  → サーバでは SIG_IGN に設定し、write() のエラーで処理

【シグナル安全な関数】
シグナルハンドラ内で呼べるのは async-signal-safe な関数のみ
安全: write(), _exit(), signal()
危険: printf(), malloc(), mutex操作
→ ハンドラではフラグを立てるだけにし、メインループで処理
```

### コンテナの基盤技術

```
【Namespace】
PID: プロセスID空間を分離
NET: ネットワークスタックを分離
MNT: ファイルシステムマウントを分離
UTS: ホスト名を分離
IPC: IPC資源を分離
USER: UID/GIDマッピングを分離
CGROUP: cgroup v2のビューを分離

【cgroup（Control Groups）】
リソース制限: CPU、メモリ、I/O帯域
優先度制御: CPUシェア
アカウンティング: リソース使用量の計測
制御: プロセス群の凍結/再開

【overlay FS】
コンテナイメージのレイヤ構造を実現
lower layer（読み取り専用）+ upper layer（書込み可能）

Docker/OCI コンテナ = Namespace + cgroup + overlay FS + seccomp
```
