default:
    just --list
run +ARGS:
    swift run GetEvents {{ARGS}}

run2:
    swift run GetEvents 2023-10-01T10:44:00+0000 2016-11-01T10:44:00+0000

build: 
    swift build -c release --arch arm64 --arch x86_64
