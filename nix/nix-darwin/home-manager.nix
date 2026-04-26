{
  self,
  username,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit self username;
    };
    users.${username} = {
      imports = [
        ../home-manager/default.nix
      ];
    };
  };
}
