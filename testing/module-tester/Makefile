.PHONY: deploy
deploy:
	cargo build --release
	avrdude -c usbasp -p m2560 -B 8kHz -U flash:w:./target/avr-none/release/module-tester.elf:e

.PHONY: flash-fuses
flash-fuses:
	avrdude -c usbasp -p m2560 -B 8kHz -U lfuse:w:0xfe:m -U hfuse:w:0x99:m -U efuse:w:0xff:m
