# コンピュータネットワーク・TCP/IP

## ネットワークアーキテクチャ（Kurose & Ross『Top-Down Approach』ベース）

### レイヤモデル

```
【TCP/IPモデル（実用）】        【OSI参照モデル（理論）】
アプリケーション層              アプリケーション層
                               プレゼンテーション層
                               セッション層
トランスポート層                トランスポート層
ネットワーク層（インターネット層） ネットワーク層
リンク層                       データリンク層
物理層                         物理層
```

### アプリケーション層

#### HTTP/HTTPS

```
HTTP/1.1: テキストベース、keep-alive、パイプライニング（実質非推奨）
HTTP/2: バイナリフレーム、多重化（1コネクションで並行ストリーム）、ヘッダ圧縮（HPACK）、サーバプッシュ
HTTP/3: QUIC上（UDP）、接続確立が高速（0-RTT可）、HoLブロッキング解消

【メソッドのセマンティクス】
GET: 冪等、キャッシュ可能、安全
POST: 非冪等、副作用あり
PUT: 冪等、リソース全体の置換
PATCH: 非冪等、リソースの部分更新
DELETE: 冪等、リソース削除

【ステータスコード】
2xx: 成功（200 OK, 201 Created, 204 No Content）
3xx: リダイレクト（301 永久, 302 一時, 304 Not Modified）
4xx: クライアントエラー（400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 429 Too Many Requests）
5xx: サーバエラー（500 Internal, 502 Bad Gateway, 503 Service Unavailable, 504 Gateway Timeout）
```

#### DNS

```
階層構造: root → TLD (.com, .jp) → 権威DNS → レコード
レコードタイプ:
  A: ドメイン → IPv4
  AAAA: ドメイン → IPv6
  CNAME: エイリアス
  MX: メールサーバ
  TXT: テキスト（SPF, DKIM, ドメイン検証）
  SRV: サービスディスカバリ
  NS: ネームサーバ委任

キャッシュ: TTLに基づく。DNS変更が浸透するまでの遅延に注意
セキュリティ: DNSSEC（署名検証）、DoH/DoT（暗号化クエリ）
```

#### WebSocket / gRPC / SSE

| プロトコル | 方向 | 接続 | ユースケース |
|-----------|------|------|-------------|
| WebSocket | 双方向 | 持続接続 | リアルタイム通知、チャット |
| gRPC | 双方向ストリーム可 | HTTP/2 | マイクロサービス間RPC |
| SSE | サーバ→クライアント | 持続接続 | ストリーミングAPI、LLM出力 |
| REST/HTTP | リクエスト-レスポンス | ステートレス | 一般的なAPI |

### トランスポート層（Stevens『TCP/IP Illustrated』補強）

#### TCP

```
【3ウェイハンドシェイク】
Client → SYN → Server
Client ← SYN+ACK ← Server
Client → ACK → Server
→ 1 RTT で接続確立

【4ウェイハンドシェイク（切断）】
Active → FIN → Passive
Active ← ACK ← Passive
Active ← FIN ← Passive
Active → ACK → Passive
→ TIME_WAIT（2MSL）: 遅延パケットの処理待ち

【フロー制御】
受信ウィンドウ（rwnd）: 受信側のバッファ容量を通知
→ 送信側は rwnd を超えて送らない

【輻輳制御】
スロースタート: cwnd を指数的に増加（1→2→4→8...）
輻輳回避: ssthresh 以降は線形増加
Fast Retransmit: 3重複ACKで即再送
Fast Recovery: cwnd を半減して輻輳回避に移行

【TCP の問題点（エージェント開発で遭遇するもの）】
HoLブロッキング: 1パケットロスで後続が全部待つ
TIME_WAIT蓄積: 短命接続が多いとポート枯渇
Nagleアルゴリズム: 小さいパケットをバッファリング → レイテンシ増
  → TCP_NODELAY で無効化（低レイテンシ通信向け）
keepalive: デフォルト2時間 → LB/NAT/FWのタイムアウトより長い
  → アプリ層 keepalive or SO_KEEPALIVE の調整
```

#### UDP

```
コネクションレス、順序保証なし、到達保証なし
用途: DNS、QUIC（HTTP/3）、リアルタイム通信、ゲーム
軽量: ヘッダ8バイト（TCPは20バイト+）
```

#### QUIC

```
UDP上に構築されたトランスポートプロトコル
  ├ 接続確立: 0-RTT（既知サーバ）/ 1-RTT（初回）
  ├ 多重化: ストリーム単位（HoLブロッキングなし）
  ├ 暗号化: TLS 1.3 統合（常に暗号化）
  ├ 接続マイグレーション: IPアドレス変更に対応（Connection ID）
  └ 輻輳制御: プラグイン可能
```

### ネットワーク層

#### IP

```
IPv4: 32ビットアドレス、NAT依存
IPv6: 128ビットアドレス、NAT不要（端末間通信）
  移行: デュアルスタック、トンネリング

【サブネット】
CIDR表記: 10.0.0.0/24 → 10.0.0.0〜10.0.0.255（256アドレス）
プライベートIP: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16

【MTU（Maximum Transmission Unit）】
Ethernet: 1500バイト
TCP MSS: MTU - IPヘッダ(20) - TCPヘッダ(20) = 1460バイト
Path MTU Discovery: ICMPで最小MTUを検出
→ MTU不一致によるパケット断片化/ブラックホールに注意
```

#### ルーティング

```
IGP（AS内）: OSPF（リンクステート）、RIP（ディスタンスベクタ）
EGP（AS間）: BGP（パスベクタ）
  BGPハイジャック: 誤った経路広告でトラフィックを横取り
```

### TLS（Transport Layer Security）

```
【TLS 1.3 ハンドシェイク】
Client → ClientHello（対応暗号スイート + key_share）
Server → ServerHello + EncryptedExtensions + Certificate + Finished
Client → Finished
→ 1 RTT で完了（TLS 1.2 は 2 RTT）
→ 0-RTT resumption（PSK）も可能（リプレイ攻撃に注意）

【暗号スイート（TLS 1.3）】
TLS_AES_128_GCM_SHA256
TLS_AES_256_GCM_SHA384
TLS_CHACHA20_POLY1305_SHA256
→ TLS 1.3 は弱い暗号を全て排除済み

【証明書検証】
1. 証明書チェーン: サーバ証明書 → 中間CA → ルートCA
2. 有効期限の確認
3. ドメイン名の一致（SAN: Subject Alternative Name）
4. 失効確認: OCSP / CRL
5. Certificate Transparency（CT）ログの確認
```

### CDN・ロードバランサ

```
【CDN】
エッジサーバにコンテンツをキャッシュ → ユーザーに近い地点から配信
キャッシュキー: URL + ヘッダ（Vary）
無効化: パージ、TTL、stale-while-revalidate

【ロードバランサ】
L4（TCP/IP層）: パケットレベルで分散。高速だがHTTPを理解しない
L7（アプリ層）: HTTPヘッダ/URLでルーティング。柔軟だがオーバーヘッド
アルゴリズム: ラウンドロビン、最小接続数、IPハッシュ、重み付き

【エージェント開発での注意点】
- LB の idle timeout（ALBデフォルト60秒）< アプリの keepalive
- gRPC はL7 LBが必要（HTTP/2の多重化をL4で扱えない）
- WebSocket は Connection: Upgrade の透過が必要
- SSE は長時間接続 → LBのタイムアウト設定
```

### NAT と問題

```
NAT: プライベートIP ←→ グローバルIPの変換
NAPT: ポート番号も変換（1グローバルIPで複数端末）

問題:
- P2P通信が困難（NAT traversal: STUN/TURN/ICE）
- ステートフル: NATテーブルのタイムアウト
  TCP: 通常5分〜数時間
  UDP: 通常30秒〜2分
  → keepalive パケットで維持
- エージェントのWebhook受信: NATの内側ではポート転送が必要
```
