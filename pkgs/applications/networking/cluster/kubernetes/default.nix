{ stdenv
, lib
, fetchFromGitHub
, which
, go
, makeWrapper
, rsync
, installShellFiles
, kubectl
, nixosTests

, components ? [
    "cmd/kubelet"
    "cmd/kube-apiserver"
    "cmd/kube-controller-manager"
    "cmd/kube-proxy"
    "cmd/kube-scheduler"
    "test/e2e/e2e.test"
  ]
}:

stdenv.mkDerivation rec {
  pname = "kubernetes";
  version = "1.23.7";

  src = fetchFromGitHub {
    owner = "kubernetes";
    repo = "kubernetes";
    rev = "v${version}";
    sha256 = "sha256-YHlcopB47HVLO/4QI8HxjMBzCpcHVnlAz3EOmZI+EG8=";
  };

  nativeBuildInputs = [ makeWrapper which go rsync installShellFiles ];

  outputs = [ "out" "man" "pause" ];

  patches = [ ./fixup-addonmanager-lib-path.patch ];

  postPatch = ''
    substituteInPlace "hack/update-generated-docs.sh" --replace "make" "make SHELL=${stdenv.shell}"
    patchShebangs ./hack
  '';

  WHAT = lib.concatStringsSep " " ([
    "cmd/kubeadm"
  ] ++ components);

  postBuild = ''
    ./hack/update-generated-docs.sh
  '';

  installPhase = ''
    runHook preInstall
    for p in $WHAT; do
      install -D _output/local/go/bin/''${p##*/} -t $out/bin
    done

    cc build/pause/linux/pause.c -o pause
    install -D pause -t $pause/bin

    rm docs/man/man1/kubectl*
    installManPage docs/man/man1/*.[1-9]

    ln -s ${kubectl}/bin/kubectl $out/bin/kubectl

    # Unfortunately, kube-addons-main.sh only looks for the lib file in either the
    # current working dir or in /opt. We have to patch this for now.
    substitute cluster/addons/addon-manager/kube-addons-main.sh $out/bin/kube-addons \
      --subst-var out

    chmod +x $out/bin/kube-addons
    patchShebangs $out/bin/kube-addons
    wrapProgram $out/bin/kube-addons --set "KUBECTL_BIN" "$out/bin/kubectl"

    cp cluster/addons/addon-manager/kube-addons.sh $out/bin/kube-addons-lib.sh

    installShellCompletion --cmd kubeadm \
      --bash <($out/bin/kubeadm completion bash) \
      --zsh <($out/bin/kubeadm completion zsh)
    runHook postInstall
  '';

  disallowedReferences = [ go ];

  GOFLAGS = [ "-trimpath" ];

  meta = with lib; {
    description = "Production-Grade Container Scheduling and Management";
    license = licenses.asl20;
    homepage = "https://kubernetes.io";
    maintainers = with maintainers; [ ] ++ teams.kubernetes.members;
    platforms = platforms.linux;
  };

  passthru.tests = nixosTests.kubernetes;
}
