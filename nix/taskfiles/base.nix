{
  taskfileVersion = "3";
  tasks = {
    fmt = "nix fmt";
    lint = "statix check . && deadnix .";
  };
}
