{ lib
, aiomysql
, aiopg
, aiosqlite
, asyncpg
, buildPythonPackage
, cryptography
, databases
, fastapi
, fetchFromGitHub
, importlib-metadata
, mysqlclient
, orjson
, poetry-core
, psycopg2
, pydantic
, pymysql
, pytest-asyncio
, pytestCheckHook
, pythonOlder
, sqlalchemy
, typing-extensions
}:

buildPythonPackage rec {
  pname = "ormar";
  version = "0.11.1";
  format = "pyproject";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "collerek";
    repo = pname;
    rev = "refs/tags/${version}";
    hash = "sha256-8d27zIlvk3ngLJ0s/5GJ8xv+PcLEu/NeA5LntaVfoAA=";
  };

  nativeBuildInputs = [
    poetry-core
  ];

  propagatedBuildInputs = [
    aiomysql
    aiosqlite
    asyncpg
    cryptography
    databases
    orjson
    psycopg2
    pydantic
    sqlalchemy
  ] ++ lib.optionals (pythonOlder "3.8") [
    typing-extensions
    importlib-metadata
  ];

  checkInputs = [
    aiomysql
    aiopg
    aiosqlite
    asyncpg
    fastapi
    mysqlclient
    psycopg2
    pymysql
    pytest-asyncio
    pytestCheckHook
  ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace 'SQLAlchemy = ">=1.3.18,<=1.4.31"' 'SQLAlchemy = ">=1.3.18"' \
      --replace 'databases = ">=0.3.2,!=0.5.0,!=0.5.1,!=0.5.2,!=0.5.3,<=0.5.5"' 'databases = ">=0.5.5"'
  '';

  disabledTests = [
    # TypeError: Object of type bytes is not JSON serializable
    "test_bulk_operations_with_json"
  ];

  pythonImportsCheck = [
    "ormar"
  ];

  meta = with lib; {
    description = "Async ORM with fastapi in mind and pydantic validation";
    homepage = "https://github.com/collerek/ormar";
    license = licenses.mit;
    maintainers = with maintainers; [ andreasfelix ];
  };
}
