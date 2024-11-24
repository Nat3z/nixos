{ pkgs, ... }: {
    home.packages = [
       (pkgs.writeShellScriptBin "fuzzy-in" ''
            
        '')
    ];
}
