architecture chip32.vm
output "chip32.bin", create

// we will put data into here that we're working on.  It's the last 1K of the 8K chip32 memory
constant rambuf = 0x1b00

constant dataslot = 0

// Host init command
constant host_init = 0x4002

// Error vector (0x0)
jp error_handler

// Init vector (0x2)
// Choose core
ld r0,#0
core r0

ld r1,#dataslot // populate data slot
ld r2,#rambuf // get ram buf position
getext r1,r2
ld r1,#ext_sgx
test r2,r1
jp z,set_sgx // Set sgx
ld r1,#ext_sgx_cap
test r2,r1
jp z,set_sgx // Set sgx

dont_set_sgx:
ld r3,#0
jp start_load

set_sgx:
ld r3,#1

start_load:
ld r1,#0 // Set address for write
ld r2,#1 // Downloading start
pmpw r1,r2 // Write ioctl_download = 1

ld r1,#4 // Set address for write
pmpw r1,r3 // Write is_sgx = 1r3

ld r1,#dataslot
ld r14,#load_err_msg
loadf r1 // Load ROM
jp nz,print_error_and_exit

ld r1,#0 // Set address for write
ld r2,#0 // Downloading end
pmpw r1,r2 // Write ioctl_download = 0

// Start core
ld r0,#host_init
host r0,r0

exit 0

// Error handling
error_handler:
ld r14,#test_err_msg

print_error_and_exit:
printf r14
exit 1

ext_sgx:
db "sgx",0

ext_sgx_cap:
db "SGX",0

test_err_msg:
db "Error",0

load_err_msg:
db "Could not load ROM",0