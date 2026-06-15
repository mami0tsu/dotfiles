{
  pkgs,
  ...
}:

let
  awsMcpServer = {
    command = "${pkgs.uv}/bin/uvx";
    args = [
      "mcp-proxy-for-aws@1.6.0"
      "https://aws-mcp.us-east-1.api.aws/mcp"
      "--metadata"
      "AWS_REGION=ap-northeast-1"
    ];
  };

  terraformMcpServer = {
    command = "${pkgs.docker_29}/bin/docker";
    args = [
      "run"
      "-i"
      "--rm"
      "hashicorp/terraform-mcp-server:1.0.0"
    ];
  };

  mcpServers = {
    aws = awsMcpServer;
    terraform = terraformMcpServer;
  };

  codexConfig = pkgs.formats.toml { };
  claudeMcpConfig = pkgs.formats.json { };
in
{
  home.file.".codex/config.toml".source = codexConfig.generate "codex-config.toml" {
    mcp_servers = mcpServers;
  };

  home.file.".claude/mcp.json".source = claudeMcpConfig.generate "claude-mcp.json" {
    mcpServers = mcpServers;
  };

  home.packages = [
    (pkgs.writeShellScriptBin "claude-with-mcp" ''
      exec ${pkgs.claude-code}/bin/claude --mcp-config "$HOME/.claude/mcp.json" --strict-mcp-config "$@"
    '')
  ];

  programs.zsh.shellAliases = {
    claude = "claude-with-mcp";
  };
}
