package main

import "core:fmt"

printf :: fmt.printf;

main :: proc() {
	infecdead();
}

infecdead :: proc() -> bool {
	printf("Hello, Infecdead!\n");
	return true;
}
