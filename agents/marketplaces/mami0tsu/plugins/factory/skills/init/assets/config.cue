// factory の設定項目、制約、既定値はこの定義で管理する。
import "struct"

#Text:   string & !=""
#Name:   string & =~"^[a-z][a-z0-9-]*$"
#Worker: "research" | "review-pr" | "review-issue" | "create-task" | "design" | "implement" | "respond"
#Limit: {
	// 同時に処理する対象の件数の上限を指定する。
	concurrency: *1 | (int & >0)
	// 定期実行するスキルの間隔を秒数で指定する。
	intervalSeconds?: int & >0
}
#Config: {
	// 最新のデフォルトブランチを定期調査するリポジトリを指定する。
	// 管理先や出力先を兼ねるとは限らず、空でもよい。
	repositories: *[] | [...{
		url: #Text
		paths: *["."] | [...#Text]
	}]
	// Issue は GitHub に保存し、タスクは指定したサービスで管理する。
	roles: {
		issues: {
			// Issue の保存先となる GitHub リポジトリの URL を指定する。
			repository: #Text & =~"^https://[^/]+/[^/]+/[^/]+/?$"
		}
		tasks: {
			// タスクを管理するサービス名を指定する。
			service: #Text
			// タスクの ID を構成するキーを指定する。
			key: #Text
		}
	}
	// 成果物の出力先を名前付きで1件以上定義する。
	// タスクごとに、この名前を使って出力先を1つ選ぶ。
	let repositoryURLs = [for repo in repositories {repo.url}]
	outputs: struct.MinFields(1) & {
		[#Name]: {
			kind: "pull-request" | "wiki" | "task-comment"
			if kind == "pull-request" {
				// 調査対象のリポジトリを指定する。
				repository: or(repositoryURLs)
			}
			if kind == "wiki" {
				// Wiki を管理するサービス名を指定する。
				service: #Text
			}
		}
	}
	// 実在するサービスの状態名を指定する。
	// 人間の判断を代行しない。
	states: {
		issues: {
			adopted:   #Text
			withdrawn: #Text
		}
		tasks: {
			// タスクが着手可能であることを示す状態名を指定する。
			ready: #Text
		}
	}
	// スキル名ごとにレビュアーを指定し、未指定なら default を使う。
	// 人間の承認は別途確認する。
	reviewers: {
		default: *[] | [...#Text]
		[#Worker]: [...#Text]
		for name, _ in loop.skills {
			"\(name)": *default | [...#Text]
		}
	}
	loop: {
		// 全スキル合計の同時処理数を指定する。
		// loop 自身と人間待ちは含めない。
		concurrency: *1 | (int & >0)
		// 全体上限と各スキルの上限を同時に守る。
		skills: {
			research: {
				concurrency:     #Limit.concurrency
				intervalSeconds: *3600 | (int & >0)
				// 未クローズの Issue の上限を指定する。
				maxOpenIssues?: int & >0
			}
			"create-task": {
				concurrency:     #Limit.concurrency
				intervalSeconds: *3600 | (int & >0)
			}
			"review-pr": {
				concurrency:     #Limit.concurrency
				intervalSeconds: *3600 | (int & >0)
			}
			"review-issue": #Limit
			design:         #Limit
			implement: {
				concurrency:     #Limit.concurrency
				intervalSeconds: *3600 | (int & >0)
			}
			respond: {
				concurrency:     #Limit.concurrency
				intervalSeconds: *3600 | (int & >0)
			}
		}
	}
}

#Config
