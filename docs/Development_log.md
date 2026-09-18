# Development Log
## Real-Time Audio Spectrum Analyzer

---

## 2026-07-14

### Project Architecture
- README.md created
- System Architecture drawing created

## 2026-07-15

### Project Setup
- Cloned repository from GitHub.
- Created local development environment.

### Added initial folder structures:
- docs/
- fpga/
- raspberry_pi/
- results/
- stm32/
- test_data/
- verif/
- visualisation/


## 2026-07-20 - 2026-07-30

### Learning SMT32CubeIDE + STM32CubeMX
### Looking through SMT32F446RE architecture
### Looking through Cortex M4 processor specifiaction


## 2026-08-01 - 2026-08-10

### Learning GPIO (Led Blinking) implementation into SMT32
### Learning UART implementation into SMT32
### Learning Timing implementation into STM32


## 2026-08-11 - 2026-08-20

### Learning ADC (and simple DAC) implementaion into SMT32
### Learning I2C implementation into SMT32
### Learning CPI implmentation into SMT32

## 2026-08-21 - 2026-08-20

### Learning DMA implementationg with I2C, UART and ADC

## 2026-08-21 - 2026-08-30

### Learning theory of Audio Sampling technology
### Learning FFT mathematics theory
### Learning FFT implementation into SMT32


## 2026-09-01 - 2026-09-10

### Learning FreeRTOS implementation in STM32
### Learning SPI connecting between STM32 and FPGA development boards

## 2026-09-15 

### Added documentation directories:
- ADC/
- I2C/
- Microphone/
- OLED Display/
- Raspbery Pi/
- Software IDE Guidelines/
- SPI/
- STM32_Board/
- UART/

### Filling the documentation directories with:
- Pictures
- Specifications
- Usage Guidelines

## 2026-09-16

### Implementing sampling of voice through Microphone
### Implementing ADC + DMA data transfering from Microphone to RAM
### Implementing Algorithm for mapping data to OLED pixels

## 20226-09-17
### Implementig I2C data transfering from RAM to OLED memory
### Working on Remaking the OLED Driver for DMA transfering
### Implementig I2C + DMA data transfering from RAM to OLED memory

## 20226-09-18
## Writing Documentation about Implementation of (MAX9814 {Microphone} <-[ADC+DMA]-> STM32 <-[I2C+DMA]-> SSD1306 {OLED Display})

### Notes
