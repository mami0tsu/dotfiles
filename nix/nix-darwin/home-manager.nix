{
  self,
  useremail,
  username,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit
        self
        username
        useremail
        ;
    };
    users.${username} = {
      imports = [
        ../home-manager/default.nix
      ];
    };
  };
}
