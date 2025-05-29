from spidriver import SPIDriver
import time

s = SPIDriver("/dev/tty.usbserial-DO00PNLE")

def spi_write(address, data):
    # Command looks like 0x00XXYYYY, with XX being the address and YYYY being the data
    command = (address << 16) | data

    # print command as hex
    # print(command.to_bytes(4, 'big'))
    
    s.sel()
    s.write(command.to_bytes(4, 'big'))
    s.unsel()
    s.unsel()

def spi_read(address, bytes):
    # Command looks like 0x80XX, with XX being the address
    command = (0x80 << 24) | address << 16
    # print(command.to_bytes(2, 'big'))
    s.sel()
    read_data = list(s.writeread(command.to_bytes(4, 'big')))
    # read_data = list(s.read(bytes))
    s.unsel()
    s.unsel()
    # if (hex(read_data[0]<< 8) == '0x2300') :
    #     data = spi_read(address, bytes)  # Retry if we get a 0x23 response
    # else :
    data = read_data[len(read_data)-bytes] << 8 | read_data[len(read_data)-bytes+1]
    return data



spi_write(0x10, 0x0000)
spi_write(0x12, 0x0000)
spi_write(0x14, 0x0000)
spi_write(0x03, 0x0000)

spi_write(0x10, 0x0001)
time.sleep(0.25)
spi_write(0x10, 0x0000)
spi_write(0x12, 0x0001)
time.sleep(0.25)
spi_write(0x12, 0x0000)
spi_write(0x14, 0x0001)
time.sleep(0.25)
spi_write(0x14, 0x0000)

# Set mode to LFSR
spi_write(0x00, 0x0001)
# Set seed
spi_write(0x01, 0xBEEF)
# Turn on red LED
spi_write(0x10, 0x0001)

# Read 10 numbers
ten_umbers = []
for i in range(10):
    ten_umbers.append(hex(spi_read(0x00, 2)))
print(f"Read 10 numbers from LFSR with 0xBEEF as set starting seed and polynomial 0 :\n{ten_umbers}\n")

# Set seed to 0xBEEF again
spi_write(0x01, 0xBEEF)
# Set polynomial
spi_write(0x03, 0x0002)
# Read 10 more numbers
ten_umbers = []
for i in range(10):
    ten_umbers.append(hex(spi_read(0x00, 2)))
print(f"Read 10 numbers from LFSR with 0xBEEF as set starting seed and polynomial 2 :\n{ten_umbers}\n")

# Generate seed from radioactive decay pulses
spi_write(0x02, 0x0000)
# Read generated seed
seed = spi_read(0x02, 2)
# Set polynomial
spi_write(0x03, 0x0000)
# Read 10 more numbers
ten_umbers = []
for i in range(10):
    ten_umbers.append(hex(spi_read(0x00, 2)))
print(f"Read 10 numbers from LFSR with {hex(seed)} as random starting seed and polynomial 0 :\n{ten_umbers}\n")

# Set mode to Decay sampling
spi_write(0x00, 0x0000)
# Read 10 numbers from radioactive decay
ten_umbers = []
for i in range(10):
    ten_umbers.append(hex(spi_read(0x00, 2)))
print(f"Read 10 numbers from radioactive decay sampling :\n{ten_umbers}\n")



# Turn off red LED and on green LED
spi_write(0x10, 0x0000)
spi_write(0x12, 0x0001)


