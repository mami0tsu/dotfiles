{
  username,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit username;
    };
    users.${username} = {
      imports = [
        ../home-manager/default.nix
      ];
    };
  };
}
