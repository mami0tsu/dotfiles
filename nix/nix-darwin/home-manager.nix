{
  inputs,
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
        inputs
        self
        username
        useremail
        ;
    };
    users.${username} = {
      imports = [
        inputs.nixvim.homeModules.nixvim
        ../home-manager/default.nix
      ];
    };
  };
}
