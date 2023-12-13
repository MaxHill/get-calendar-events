default:
    just --list
run +ARGS:
    swift run get-calendar-events {{ARGS}}

run2:
    swift run get-calendar-events 2023-10-01T00:00:00+0000 2023-11-01T00:00:00+0000

build: 
    swift build -c release --arch arm64 --arch x86_64
