{ buildPythonPackage
, cython
, fetchFromGitHub
, isPy38
, lib
, lz4
, numpy
, pandas
, pytestCheckHook
, python-dateutil
, python-snappy
, pythonOlder
, zstandard
}:

buildPythonPackage rec {
  pname = "fastavro";
  version = "1.5.1";

  disabled = pythonOlder "3.6";
  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "refs/tags/${version}";
    sha256 = "sha256-kI1KRJ4iQP19hYTSRQ6VHZz+Pg5Ar7CaOB7yUJbHm2Q=";
  };

  preBuild = ''
    export FASTAVRO_USE_CYTHON=1
  '';

  nativeBuildInputs = [ cython ];

  checkInputs = [
    lz4
    numpy
    pandas
    pytestCheckHook
    python-dateutil
    python-snappy
    zstandard
  ];

  # Fails with "AttributeError: module 'fastavro._read_py' has no attribute
  # 'CYTHON_MODULE'." Doesn't appear to be serious. See https://github.com/fastavro/fastavro/issues/112#issuecomment-387638676.
  disabledTests = [ "test_cython_python" ];

  # CLI tests are broken on Python 3.8. See https://github.com/fastavro/fastavro/issues/558.
  disabledTestPaths = lib.optionals isPy38 [ "tests/test_main_cli.py" ];

  pythonImportsCheck = [ "fastavro" ];

  meta = with lib; {
    description = "Fast read/write of AVRO files";
    homepage = "https://github.com/fastavro/fastavro";
    license = licenses.mit;
    maintainers = with maintainers; [ samuela ];
  };
}
