{
  lib,
  self,
  ...
}:

let
  skillsRoot = "${self}/skills";
  entries = builtins.readDir skillsRoot;

  # SKILL.md を持つディレクトリだけを Agent Skill として扱う。
  # これにより、skills/ 配下にメモや作成途中の雛形を置いてもインストールされない。
  skillNames = builtins.filter (
    name: entries.${name} == "directory" && builtins.pathExists "${skillsRoot}/${name}/SKILL.md"
  ) (builtins.attrNames entries);

  linkSkills =
    agentDir:
    builtins.listToAttrs (
      map (name: {
        # skills ディレクトリ全体は管理せず、dotfiles 管理の skill だけを個別にリンクする。
        # 端末ごとに別管理の skill があっても、同じディレクトリに同居させられる。
        name = "${agentDir}/skills/${name}";
        value.source = "${skillsRoot}/${name}";
      }) skillNames
    );
in
{
  home.file = lib.mkMerge [
    (linkSkills ".codex")
    (linkSkills ".claude")
  ];
}
