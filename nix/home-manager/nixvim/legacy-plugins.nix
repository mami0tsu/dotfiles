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
    rev = "62c86c63acd88f3f86e5613ce9396fd7ce269539";
    hash = "sha256-Y6LKcmR4zZbOJ8PvpWxUcCkKJzToFe4Xo5DGlfxz1xQ=";
  };
  vim-goimports = buildPlugin {
    pname = "vim-goimports";
    owner = "mattn";
    repo = "vim-goimports";
    # renovate: datasource=git-refs packageName=https://github.com/mattn/vim-goimports currentValue=master
    rev = "66e23a2a5f76d8a18eea0258c733f23969a607a3";
    hash = "sha256-YjuYLuMiTP9Wv5+1Dt4Rn5eXkwOJexpT8H8ZxgMLeGk=";
  };
  deol-nvim = buildPlugin {
    pname = "deol-nvim";
    owner = "Shougo";
    repo = "deol.nvim";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/deol.nvim currentValue=master
    rev = "6903fdd4ed0c13850511655ba1b23d4b0f01bf23";
    hash = "sha256-J9dftuSAmlkuurkA4GwYk67E4mKPow4o2FCoKsH2+zU=";
  };

  ddc-ui-inline = buildPlugin {
    pname = "ddc-ui-inline";
    owner = "Shougo";
    repo = "ddc-ui-inline";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-ui-inline currentValue=main
    rev = "4465bc5a201122efd2ac239b81039d54ad94518f";
    hash = "sha256-XJ7Ed022OxEK5jKvdCjrqT1DaWP1QahsAIi7fT//PWM=";
  };
  ddc-buffer = buildPlugin {
    pname = "ddc-buffer";
    owner = "matsui54";
    repo = "ddc-buffer";
    # renovate: datasource=git-refs packageName=https://github.com/matsui54/ddc-buffer currentValue=main
    rev = "bc2416de3629693f88e66870ca11090571f265ec";
    hash = "sha256-snNlvHeIGsi7Iz36AWItf7IsVHopvrsEmDTf0MR8mUw=";
  };
  ddc-source-shell_native = buildPlugin {
    pname = "ddc-source-shell_native";
    owner = "Shougo";
    repo = "ddc-source-shell_native";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-shell_native currentValue=main
    rev = "86686bd68cc7d26866ee5cf8cdfc1808f20c42a8";
    hash = "sha256-x2KSFj6LPZIPLZRyqp0hOxDA7o5cLgimkSWKYomdgiw=";
  };
  ddc-source-input = buildPlugin {
    pname = "ddc-source-input";
    owner = "Shougo";
    repo = "ddc-source-input";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-input currentValue=main
    rev = "4f0def28b394c7a7e421a9f5c07e6b93b010cfaa";
    hash = "sha256-GicKcOu380nZQowRLYpfnhnuyn2bsJ+qb8rNdice4ow=";
  };
  ddc-source-rg = buildPlugin {
    pname = "ddc-source-rg";
    owner = "Shougo";
    repo = "ddc-source-rg";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-rg currentValue=main
    rev = "de4f4db7fcb981683ef51c1e5816ba7411f4ec65";
    hash = "sha256-X+DG8mpn49DQ1nBW3rRoj/XBNsFvU+EnJ2w255BKTB4=";
  };
  ddc-source-line = buildPlugin {
    pname = "ddc-source-line";
    owner = "Shougo";
    repo = "ddc-source-line";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-line currentValue=main
    rev = "436750c3394eb93c9316fa7dba9f1b551f9bac93";
    hash = "sha256-hIvCOE9ITJ6pXq7ifrSqnPV/BsZNrHSnvhedD5TKW0M=";
  };
  ddc-source-cmdline = buildPlugin {
    pname = "ddc-source-cmdline";
    owner = "Shougo";
    repo = "ddc-source-cmdline";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-cmdline currentValue=main
    rev = "139f85f05d2c6d83575138f8acaba4b03ce2c611";
    hash = "sha256-dZF3sLxhNIUtZhV9IVEl0Ki3zp82rV7PlpsMy5Fiki8=";
  };
  ddc-source-cmdline-history = buildPlugin {
    pname = "ddc-source-cmdline-history";
    owner = "Shougo";
    repo = "ddc-source-cmdline-history";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-source-cmdline-history currentValue=main
    rev = "ffbae40f46c08a482b7a5dd60fafe04bcbb13320";
    hash = "sha256-S0W8lqy7EyWYVaME0WHZ9dNy03KliDajkWyNlcE2ZFY=";
  };
  ddc-filter-matcher_length = buildPlugin {
    pname = "ddc-filter-matcher_length";
    owner = "Shougo";
    repo = "ddc-filter-matcher_length";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-matcher_length currentValue=main
    rev = "003f7b05becf4e34f704800cdf20a167ac0326b2";
    hash = "sha256-sZARUPCAocmC8pyvWe92gT0fTpcQFU/q7wA6RpNrctk=";
  };
  ddc-filter-matcher_prefix = buildPlugin {
    pname = "ddc-filter-matcher_prefix";
    owner = "Shougo";
    repo = "ddc-filter-matcher_prefix";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-matcher_prefix currentValue=main
    rev = "ade87a25a56a7299b427f875a39383fe989ae3b3";
    hash = "sha256-k4MYPQoDaK5AfCCBve2igtB1kGlLUNzhySu5emnvwhM=";
  };
  ddc-filter-matcher_vimregexp = buildPlugin {
    pname = "ddc-filter-matcher_vimregexp";
    owner = "Shougo";
    repo = "ddc-filter-matcher_vimregexp";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-matcher_vimregexp currentValue=main
    rev = "19e283abc95ebbe3785c3cff5acf3dc6fb0e29c4";
    hash = "sha256-nX2zzm98CAzu4kFGrB+tfhlfD3DZp2/w/bYM2cnxjJY=";
  };
  ddc-filter-sorter_head = buildPlugin {
    pname = "ddc-filter-sorter_head";
    owner = "Shougo";
    repo = "ddc-filter-sorter_head";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-sorter_head currentValue=main
    rev = "692cb5e6af0617e1d545697fcff5fb43e4f2b6c5";
    hash = "sha256-4PXXIASxl2HvrRCD9Xj94qZtwzZn/vETCuJc+T0PiSs=";
  };
  ddc-filter-converter_remove_overlap = buildPlugin {
    pname = "ddc-filter-converter_remove_overlap";
    owner = "Shougo";
    repo = "ddc-filter-converter_remove_overlap";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-converter_remove_overlap currentValue=main
    rev = "685ab33137e50d2c3e7a0f0beb89fd1b2ae81168";
    hash = "sha256-CcJT/jHCuBTNtpQ3lVtF/K0mb2GS7G6UkC8k04cDqc8=";
  };
  ddc-filter-converter_truncate_abbr = buildPlugin {
    pname = "ddc-filter-converter_truncate_abbr";
    owner = "Shougo";
    repo = "ddc-filter-converter_truncate_abbr";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddc-filter-converter_truncate_abbr currentValue=main
    rev = "0dd6b50a675d2fb9beb18ba4cd35dbd23b3f58dd";
    hash = "sha256-HbnHmRj7OiJJx9vcBEdsHUjh2XtEtHn87Qz3yguuWug=";
  };

  ddu-vim = buildPlugin {
    pname = "ddu-vim";
    owner = "Shougo";
    repo = "ddu.vim";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu.vim currentValue=main
    rev = "7190c51ec461211ea1c06d74d577b5a29cc43d8c";
    hash = "sha256-/YnFsHzLd19DMhQen/ZKIWSlZau9j9EqKaMCs+9dsKE=";
  };
  ddu-commands-vim = buildPlugin {
    pname = "ddu-commands-vim";
    owner = "Shougo";
    repo = "ddu-commands.vim";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-commands.vim currentValue=main
    rev = "a2f7be0be57f3440e5130238816c62a486a79c74";
    hash = "sha256-D/1liN0tuqCjhzZmrv+r2Sgd6aSt/kHkPlINmm1P9UM=";
  };
  ddu-ui-ff = buildPlugin {
    pname = "ddu-ui-ff";
    owner = "Shougo";
    repo = "ddu-ui-ff";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-ui-ff currentValue=main
    rev = "38c0c5d93a6c877ddb6e47371491d02b0b4a8ab9";
    hash = "sha256-dsfGFKLxSpShtTyFbltI38xv+uqviDuzAYOBgsX+T+M=";
  };
  ddu-ui-filer = buildPlugin {
    pname = "ddu-ui-filer";
    owner = "Shougo";
    repo = "ddu-ui-filer";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-ui-filer currentValue=main
    rev = "9cf6e7b1a6632eaf1c5af8a8ac89191efc879fff";
    hash = "sha256-2GdhNuh8mZxpYNmOT0wdzSsWJBTeD/JXpUSKwtdD6eY=";
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
    rev = "dc1f5b73bbb707bb0ab60972814822c8ab97f025";
    hash = "sha256-KjwK7cljPy7gBj+DK2eocGxG6EkQBPLmnL/QlwYWF1Y=";
  };
  ddu-source-file_rec = buildPlugin {
    pname = "ddu-source-file_rec";
    owner = "Shougo";
    repo = "ddu-source-file_rec";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-source-file_rec currentValue=main
    rev = "e4cd38a167bebca453f7244d999267ce66814b1b";
    hash = "sha256-8W6q8irRJsQBA19x/SKs67uDaueNPRb9nso4svQyqTY=";
  };
  ddu-source-line = buildPlugin {
    pname = "ddu-source-line";
    owner = "Shougo";
    repo = "ddu-source-line";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-source-line currentValue=main
    rev = "e13f2bf42f3343bea5e869199e6976fe7f82a9b0";
    hash = "sha256-SYAj9AfqjHVTELe81rxHFVjmdwkIAvw98QNd3EyhNUA=";
  };
  ddu-source-rg = buildPlugin {
    pname = "ddu-source-rg";
    owner = "shun";
    repo = "ddu-source-rg";
    # renovate: datasource=git-refs packageName=https://github.com/shun/ddu-source-rg currentValue=main
    rev = "42b928ed4e921c71cf185db0bb6b3cb6c85d0399";
    hash = "sha256-v7oOAxhTEUzLQ4XwPk3FrjemIu11ryfFB8bqh7+EFC0=";
  };
  ddu-kind-file = buildPlugin {
    pname = "ddu-kind-file";
    owner = "Shougo";
    repo = "ddu-kind-file";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-kind-file currentValue=main
    rev = "649be2f0eee8296ea7772d1916dceb873feac3ce";
    hash = "sha256-vR7TRZrKK4A5tPnZxS3DYo+exvvi71AzvojOccOdYuk=";
  };
  ddu-kind-word = buildPlugin {
    pname = "ddu-kind-word";
    owner = "Shougo";
    repo = "ddu-kind-word";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-kind-word currentValue=main
    rev = "4d4b6f707887eb6fe0a2e99410d434db100981b4";
    hash = "sha256-nLH0HvPxzl5G9SQRJ1fXXKQ9i7yhoIdqxT0oySFDP98=";
  };
  ddu-filter-matcher_files = buildPlugin {
    pname = "ddu-filter-matcher_files";
    owner = "Shougo";
    repo = "ddu-filter-matcher_files";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-filter-matcher_files currentValue=main
    rev = "21a40f6ceb528f486af8e20c7783cd8bf29fe411";
    hash = "sha256-qaJIelWaVRot+1OElEz9tIKdCy4BT1Mpv0qShS9mm70=";
  };
  ddu-filter-matcher_relative = buildPlugin {
    pname = "ddu-filter-matcher_relative";
    owner = "Shougo";
    repo = "ddu-filter-matcher_relative";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-filter-matcher_relative currentValue=main
    rev = "5102718f559d5644a6d08070ca6f7024b687ddf4";
    hash = "sha256-vVnMcpzVwCfH7NcmYYCdsGn1iQSwwdtl1jgp4jS2JOo=";
  };
  ddu-filter-matcher_substring = buildPlugin {
    pname = "ddu-filter-matcher_substring";
    owner = "Shougo";
    repo = "ddu-filter-matcher_substring";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-filter-matcher_substring currentValue=main
    rev = "01eae40a1aedec5093d6b20f48441acc8bc4436c";
    hash = "sha256-GhlaKrspqJHgW/Brsu6GBTsHk7q6qvREzOmysSX1Mjk=";
  };
  ddu-filter-sorter_alpha = buildPlugin {
    pname = "ddu-filter-sorter_alpha";
    owner = "Shougo";
    repo = "ddu-filter-sorter_alpha";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-filter-sorter_alpha currentValue=main
    rev = "7bf4e74ac8ee11bfbef30b1b50b1b6c0b248a5c6";
    hash = "sha256-G6MjjRM4F8wtc/NbgddTCjNKqBmQVzAIbT+hjKu1MIw=";
  };
  ddu-column-filename = buildPlugin {
    pname = "ddu-column-filename";
    owner = "Shougo";
    repo = "ddu-column-filename";
    # renovate: datasource=git-refs packageName=https://github.com/Shougo/ddu-column-filename currentValue=main
    rev = "be74daf08ebe715574b758e4a4ee86db33833c16";
    hash = "sha256-LhBw8YRAtAKu8KexGOBVQ7z74y1cG1/kbajCxak1FNU=";
  };
  moody-nvim = buildPlugin {
    pname = "moody-nvim";
    owner = "svampkorg";
    repo = "moody.nvim";
    # renovate: datasource=git-refs packageName=https://github.com/svampkorg/moody.nvim currentValue=main
    rev = "a969f9e4325a3b2c225df3b635e1fd62f1769029";
    hash = "sha256-GrulZ/xvPjpo/xCGgxua6LOVWbANTWxZ0G3/btHoTW8=";
    nvimSkipModules = [ "moody.statuscolumn" ];
  };
}
