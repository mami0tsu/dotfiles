// factory の設定項目、制約、既定値はこの定義で管理する。
import "struct"

#Text:   string & !=""
#Name:   string & =~"^[a-z][a-z0-9-]*$"
#Worker: "research" | "review" | "register" | "plan" | "design" | "implement" | "release" | "respond"
#Limit: {
	// 同時に処理する対象件数の上限を指定する。
	concurrency: *1 | (int & >0)
}
#Adapter: {
	// factory 同梱なら builtin、導入済みの別プラグインなら external を指定する。
	source: "builtin" | "external"
	// 呼び出すスキルの名前を指定する。
	skill: #Name
	if source == "external" {
		// 外部スキルを提供するプラグインの識別子を指定する。
		plugin: #Text
	}
}
#CollectionTarget: {
	// アイデアやタスクの集合を操作する。
	kind: "collection"
	// 操作先の正本ID/URLを指定する。
	container: #Text
}
#FileTarget: {
	// ファイルを読み書きする。
	kind: "file"
	// 操作先の正本ID/URLを指定する。
	container: #Text
	// container 内の記録先を指定する。
	path: #Text
}
#Subject: {
	// 現在処理中のアイデアかタスクをコメント先に指定する。
	role: "ideas" | "tasks"
} | {
	// 固定のコメント先をURLで指定する。
	url: #Text
}
#CommentTarget: {
	// 指定対象のコメントを読み書きする。
	kind: "comment"
	// コメント先は実行時に解決する。
	subject: #Subject
}
#ChangeTarget: {
	// 変更提案を操作する。
	kind: "change"
	// 操作先の正本ID/URLを指定する。
	container: #Text
	// 変更提案の取り込み先を指定する。
	base: #Text
}
#OutputTarget: #FileTarget | #CommentTarget | #ChangeTarget
#Config: {
	// 定期調査するリポジトリを指定する。
	// 管理先や出力先を兼ねるとは限らず、空でもよい。
	repositories: *[] | [...{
		url:      #Text
		revision: *"main" | #Text
		paths: *["."] | [...#Text]
	}]
	research: {
		// 前回の定期調査から次の調査までの秒数を指定する。
		intervalSeconds: *86400 | (int & >0)
	}
	// 名前を付けたアダプターを定義する。
	// 外部でも自由な設定項目は追加しない。
	adapters: [#Name]: #Adapter
	#AdapterName: or([for name, _ in adapters {name}])

	// アイデアとタスクそれぞれの管理先を指定する。
	roles: {
		ideas: {
			adapter: #AdapterName
			target:  #CollectionTarget
		}
		tasks: {
			adapter: #AdapterName
			target:  #CollectionTarget
		}
	}
	// タスクが名前で1つ選ぶ出力先を定義する。
	// 同じアダプターを複数の管理先や出力先へ割り当てられる。
	// 出力先は少なくとも1件指定する。
	outputs: struct.MinFields(1) & {
		[#Name]: {
			adapter: #AdapterName
			target:  #OutputTarget
		}
	}
	// 実在するサービスの状態名を指定する。
	// 人間の判断を代行しない。
	states: {
		ideas: {
			adopted:   #Text
			withdrawn: #Text
		}
		tasks: {
			ready:           #Text
			"release-ready": #Text
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
			research:  #Limit
			review:    #Limit
			register:  #Limit
			plan:      #Limit
			design:    #Limit
			implement: #Limit
			release:   #Limit
			respond:   #Limit
		}
	}
}

#Config
