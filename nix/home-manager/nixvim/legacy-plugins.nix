{ pkgs }:

let
  buildPlugin =
    {
      pname,
      owner,
      repo,
      rev,
      hash,
      nvimSkipModules ? [ ],
    }:
    pkgs.vimUtils.buildVimPlugin {
      inherit pname nvimSkipModules;
      version = rev;
      src = pkgs.fetchFromGitHub {
        inherit owner repo rev;
        sha256 = hash;
      };
    };
in
{
  previm = buildPlugin {
    pname = "previm";
    owner = "previm";
    repo = "previm";
    # renovate: datasource=git-refs packageName=https://github.com/previm/previm currentValue=master
    rev = "0918a3a7263a840bf9038e2d599a965d320a6b49";
    hash = "0r0mqipcq71lwcs2cbj2d37mbjlqbfcprkzdv62pvxzfn8yhrvf5";
  };
  vim-goimports = buildPlugin {
    pname = "vim-goimports";
    owner = "mattn";
    repo = "vim-goimports";
    # renovate: datasource=git-refs packageName=https://github.com/mattn/vim-goimports currentValue=master
    rev = "e50dae830c3cc405003bbc79e90c2dfb5c8da7f5";
    hash = "0xgbf1g5d758pcalba1j7xlv4i6c9m9v22vxn7qh8fmws7w24mqz";
  };
  deol-nvim = buildPlugin {
    pname = "deol-nvim";
    owner = "Shougo";
    repo = "deol.nvim";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/deol.nvim currentValue=master
    rev = "9c2c97b99b236bc9a0a768e696aea466b959a396";
    hash = "092fjbb0aywiffrhf9vdcg9i7s0rs9cf65c2mnj8il5aag180ig0";
  };

  ddc-ui-inline = buildPlugin {
    pname = "ddc-ui-inline";
    owner = "Shougo";
    repo = "ddc-ui-inline";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-ui-inline currentValue=main
    rev = "9c7103fe4262a081a8e38a7a2e3e5939403818f4";
    hash = "15y0nl2yv9wkr799nbr45q1pai2lbc54yv9wc3yh9p1wl7d64zx5";
  };
  ddc-buffer = buildPlugin {
    pname = "ddc-buffer";
    owner = "matsui54";
    repo = "ddc-buffer";
    # renovate: datasource=git-refs packageName=https://github.com/matsui54/ddc-buffer currentValue=main
    rev = "f332e16ed82ec31c4a5afe3da5117e0b5e0c6902";
    hash = "15nsw4c7z76ax87kh2sm7yj6l0k7jbsyvn3za8avj9lspmz222hf";
  };
  ddc-source-shell_native = buildPlugin {
    pname = "ddc-source-shell_native";
    owner = "Shougo";
    repo = "ddc-source-shell_native";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-shell_native currentValue=main
    rev = "6c71c69ea84fddb9bad47cb68741c58696988e52";
    hash = "04yijf4sav05sp75ip9s2swgj1n15prdbmvx9hhl521k7j5szk6y";
  };
  ddc-source-input = buildPlugin {
    pname = "ddc-source-input";
    owner = "Shougo";
    repo = "ddc-source-input";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-input currentValue=main
    rev = "d8d97a1f8f6657a992dd5d21dfe851a188e7177d";
    hash = "1llvi1rim0xjd6lqc99r7vrjzb6y3akba0fc242hayhn9myhlyhh";
  };
  ddc-source-rg = buildPlugin {
    pname = "ddc-source-rg";
    owner = "Shougo";
    repo = "ddc-source-rg";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-rg currentValue=main
    rev = "5959f0ed4d9b8d322913ebb11197c943a466bebb";
    hash = "0f6lh29fpv6s82fwxjpqj4lfhm6ap1rbw6kww6zh0fmqqij3pra5";
  };
  ddc-source-line = buildPlugin {
    pname = "ddc-source-line";
    owner = "Shougo";
    repo = "ddc-source-line";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-line currentValue=main
    rev = "6d846d6d82ec3420eb7e01013c2821eafcc9bed1";
    hash = "0dqjj5ahlffybhgg5f5mcq636li8a6kzf4pzk4w6jxwm33p4h72m";
  };
  ddc-source-cmdline = buildPlugin {
    pname = "ddc-source-cmdline";
    owner = "Shougo";
    repo = "ddc-source-cmdline";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-cmdline currentValue=main
    rev = "a35f8f60e902098117a275609d73b89a2b39e1ae";
    hash = "19g067v8wwiph15q6bhc7axgs9fmzqskjgqxfc8mr9amigw2294b";
  };
  ddc-source-cmdline-history = buildPlugin {
    pname = "ddc-source-cmdline-history";
    owner = "Shougo";
    repo = "ddc-source-cmdline-history";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-cmdline-history currentValue=main
    rev = "3fe2600bec5aab81fc70cf9777cf2081f3f8753e";
    hash = "1nysg6s6nba9hdrmj44g6m7c84vkwvs3sam882swygvssqa1qay7";
  };
  ddc-filter-matcher_length = buildPlugin {
    pname = "ddc-filter-matcher_length";
    owner = "Shougo";
    repo = "ddc-filter-matcher_length";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-matcher_length currentValue=main
    rev = "fc438eaefd4ed3bc7b7f9c676a91c33f1fe5f72b";
    hash = "1xcnciala2w1wihxycdjj1vdhqwpchf2v6r5js7ssg2sy15f6g4z";
  };
  ddc-filter-matcher_prefix = buildPlugin {
    pname = "ddc-filter-matcher_prefix";
    owner = "Shougo";
    repo = "ddc-filter-matcher_prefix";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-matcher_prefix currentValue=main
    rev = "06c63fe7963b423c7fb3f98634d480b60736d104";
    hash = "0yrfvmnkg3z50vajyarrqh6l6gy79dxdff1z2q2wfrh8gyyhpkac";
  };
  ddc-filter-matcher_vimregexp = buildPlugin {
    pname = "ddc-filter-matcher_vimregexp";
    owner = "Shougo";
    repo = "ddc-filter-matcher_vimregexp";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-matcher_vimregexp currentValue=main
    rev = "4ae8876526d73dab337f776b2be7b76f85af3b71";
    hash = "1267xgkd96898acvilss4406ym58binf02wankpxv5jql95n9nsi";
  };
  ddc-filter-sorter_head = buildPlugin {
    pname = "ddc-filter-sorter_head";
    owner = "Shougo";
    repo = "ddc-filter-sorter_head";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-sorter_head currentValue=main
    rev = "debad483b95e4a4029f87a6aa7b589277fbe21d6";
    hash = "0cb75z2swypwrnmh6yri24s941a5pny3nxyi9h6jbmmnbxkag9bc";
  };
  ddc-filter-converter_remove_overlap = buildPlugin {
    pname = "ddc-filter-converter_remove_overlap";
    owner = "Shougo";
    repo = "ddc-filter-converter_remove_overlap";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-converter_remove_overlap currentValue=main
    rev = "f3b519bb88be428a6582544fb78ddb48e3a2df99";
    hash = "12ah619giyh8dwc7sqavsha2kvpci9vics3nrlpmrqhd1p8m5h3v";
  };
  ddc-filter-converter_truncate_abbr = buildPlugin {
    pname = "ddc-filter-converter_truncate_abbr";
    owner = "Shougo";
    repo = "ddc-filter-converter_truncate_abbr";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-converter_truncate_abbr currentValue=main
    rev = "e9a6242dd968c884e559ccc005f9ed4232c3ffb1";
    hash = "0qijhl3xg0nfzq116idwjac2wf6ynx897r5xzri8bi7wb8b2zpa4";
  };

  ddu-vim = buildPlugin {
    pname = "ddu-vim";
    owner = "Shougo";
    repo = "ddu.vim";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu.vim currentValue=main
    rev = "1d5c9f11d6cdc4a8b550c3cace891e8e011cc22d";
    hash = "0g0s33i7r2xa4ymdsghlvi9lk3jnnpd001dslvc1xc0ha09x0vvj";
  };
  ddu-commands-vim = buildPlugin {
    pname = "ddu-commands-vim";
    owner = "Shougo";
    repo = "ddu-commands.vim";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-commands.vim currentValue=main
    rev = "ddae8958a88324f106151462aad62dd4c8338028";
    hash = "1p20h5qv3kshn0ck60qw1b4s28j4364a24r1afcv66m8hxz7srg5";
  };
  ddu-ui-ff = buildPlugin {
    pname = "ddu-ui-ff";
    owner = "Shougo";
    repo = "ddu-ui-ff";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-ui-ff currentValue=main
    rev = "7b20ec7c71ee6b13425234c0386baca6b6b629f8";
    hash = "10r096469265b017fq92bakj7405j9h8icmnrf8xxfw6p3bw9ad5";
  };
  ddu-ui-filer = buildPlugin {
    pname = "ddu-ui-filer";
    owner = "Shougo";
    repo = "ddu-ui-filer";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-ui-filer currentValue=main
    rev = "cb9499b0998dea6fb2ca72085b0d562f2f8a3139";
    hash = "0l4mfgyvimj7njm68fjlr3714grl4zaslnyz19yb48c2jk6pgg61";
  };
  ddu-source-buffer = buildPlugin {
    pname = "ddu-source-buffer";
    owner = "shun";
    repo = "ddu-source-buffer";
    # renovate: datasource=git-refs packageName=https://github.com/shun/ddu-source-buffer currentValue=main
    rev = "1238c09bccb1d4814f36d83ef864cbb2b2ca9895";
    hash = "1isdzz3d6av3dq4swal8v5msc39qmmw2g83biw09q68larw5vhcw";
  };
  ddu-source-file = buildPlugin {
    pname = "ddu-source-file";
    owner = "Shougo";
    repo = "ddu-source-file";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-source-file currentValue=main
    rev = "7cbcd568ec3446c0ea6cad83f902fc37b8e02774";
    hash = "1jq8034fm80j8zbrwhmqfxfz50k2a11dkka3vjgn99nky28yqh23";
  };
  ddu-source-file_rec = buildPlugin {
    pname = "ddu-source-file_rec";
    owner = "Shougo";
    repo = "ddu-source-file_rec";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-source-file_rec currentValue=main
    rev = "32f16fb90aa805ed16ea10dcbb347e1ae7b054a6";
    hash = "03czcyfvy4ks7ypi0wghzgka3pnbjcqbrrkmxb8nq1fh00h9iqnh";
  };
  ddu-source-line = buildPlugin {
    pname = "ddu-source-line";
    owner = "Shougo";
    repo = "ddu-source-line";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-source-line currentValue=main
    rev = "e5f21c88b7887f99cb47727516f6526c8e2df7d1";
    hash = "0qg7didp1ihmiiczr7hnc0sk0bxx7l5ibbv7gdbmkb7lzzmlaffk";
  };
  ddu-source-rg = buildPlugin {
    pname = "ddu-source-rg";
    owner = "shun";
    repo = "ddu-source-rg";
    # renovate: datasource=git-refs packageName=https://github.com/shun/ddu-source-rg currentValue=main
    rev = "b993601f00aa6fabd993e16f531338368464a796";
    hash = "1mggypajm16wv71s26fg6k2c5n1vgpjfnldmi72lk643c3d6ka47";
  };
  ddu-kind-file = buildPlugin {
    pname = "ddu-kind-file";
    owner = "Shougo";
    repo = "ddu-kind-file";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-kind-file currentValue=main
    rev = "1287d05ce63853ac9c7847d2720402eccdc4a313";
    hash = "1qfiqkg0wkpl0s17zx1wbc4i63n7mly5s7lqsbnax0gg6b21p3y9";
  };
  ddu-kind-word = buildPlugin {
    pname = "ddu-kind-word";
    owner = "Shougo";
    repo = "ddu-kind-word";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-kind-word currentValue=main
    rev = "833fc9b99f3a948f8a1d61983b6bcc4bfe38d33c";
    hash = "0aan45xm9pgi22j7n09srlmpvlp3v77cgkqz79g47vnyq1hxrqpg";
  };
  ddu-filter-matcher_files = buildPlugin {
    pname = "ddu-filter-matcher_files";
    owner = "Shougo";
    repo = "ddu-filter-matcher_files";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-filter-matcher_files currentValue=main
    rev = "adf5ec3af025190c45ff40ac40f79a52afc9be2b";
    hash = "0l1s620i46qk0ndsjwcwiq487ci331nacis561frs6agxw8xp12w";
  };
  ddu-filter-matcher_relative = buildPlugin {
    pname = "ddu-filter-matcher_relative";
    owner = "Shougo";
    repo = "ddu-filter-matcher_relative";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-filter-matcher_relative currentValue=main
    rev = "b94f477541f0e0a3f538041ac321d48ad7e486a5";
    hash = "09vzmvda8zls6hka8as6j8sfqhalb99wsa1lbv60jwgxgbgk0i2g";
  };
  ddu-filter-matcher_substring = buildPlugin {
    pname = "ddu-filter-matcher_substring";
    owner = "Shougo";
    repo = "ddu-filter-matcher_substring";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-filter-matcher_substring currentValue=main
    rev = "3ce57b5293f5922ea84d6dc934abbfc1c5c38d7f";
    hash = "113zsirz16xclari2666a4r2wfng801hhrx42dg24rvawmzyx1nl";
  };
  ddu-filter-sorter_alpha = buildPlugin {
    pname = "ddu-filter-sorter_alpha";
    owner = "Shougo";
    repo = "ddu-filter-sorter_alpha";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-filter-sorter_alpha currentValue=main
    rev = "91df49ceed7cf344b166016fe0a1ca911a709d05";
    hash = "1jxwij2hgm78lzs2mfl2wbh94v0yaxmk9d8d25gph4sd3d3bpz99";
  };
  ddu-column-filename = buildPlugin {
    pname = "ddu-column-filename";
    owner = "Shougo";
    repo = "ddu-column-filename";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-column-filename currentValue=main
    rev = "03506e0e20c2de3069c5457a5ed1099b550db3f1";
    hash = "00aw0r496nrzs6d5myssfgsj2h38g1msza8ah841ifxfkih4q4bb";
  };
  moody-nvim = buildPlugin {
    pname = "moody-nvim";
    owner = "svampkorg";
    repo = "moody.nvim";
    # renovate: datasource=git-refs packageName=https://github.com/svampkorg/moody.nvim currentValue=main
    rev = "263f5f89277f40932c1cd7aca010bd38256fda17";
    hash = "0xp4grqy4ygc8hyq47isjvqrq7c89syi97cbdrjsvw4z0iwl3zwz";
    nvimSkipModules = [ "moody.statuscolumn" ];
  };
}
