This directory contains a test image that can be used with QEMU 5.0+ to
verify TF-M builds.

## TF-M Build Script

The image was built using the following build script and TF-M, based on
commit `b157dca40dcf2051a0420cb16d659a6aa69335d7`:

```
#!/bin/bash
# Copyright (c) 2020, Linaro. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Exit on error
set -e

# Cleanup previous build artifacts
rm -rf CMakeCache.txt CMakeFiles cmake_install.cmake install bl2 secure_fw app unit_test test

# Set the readlink binary name:
if [ "$(uname)" == "Darwin" ]; then
    # For OS X this should be be 'greadlink' (brew install coreutils)
    readlink=greadlink
else
    # For Linux this should be 'readlink'
    readlink=readlink
fi

# Set the config file to use
configfile=ConfigRegression

target=AN521

# Generate the S and NS makefiles
cmake -G"Unix Makefiles" \
        -DPROJ_CONFIG=`$readlink -f ../configs/$configfile.cmake` \
        -DTARGET_PLATFORM=$target \
        -DCMAKE_BUILD_TYPE=Debug \
        -DBL2=False \
        -DCOMPILER=GNUARM \
        ../

# Build the binaries
make install

# Convert S and NS binaries to .hex file
arm-none-eabi-objcopy -S --gap-fill 0xff -O ihex \
        install/outputs/$target/tfm_s.axf tfm_s.hex
arm-none-eabi-objcopy -S --gap-fill 0xff -O ihex \
        install/outputs/$target/tfm_ns.axf tfm_ns.hex

# Generate a single hex file for convenience/QEMU sake
srec_cat tfm_s.hex -Intel tfm_ns.hex -Intel -o tfm_full.hex -Intel
```

## Manually Running the Image

The output image (`tfm_full_b157dca4.hex`) can be manually run as follows:

```bash
qemu-system-arm -M mps2-an521 -device loader,file=tfm_full_b157dca4.hex -serial stdio
```

### Output

And should produce the following (truncated) output:

```
...
> Executing 'TFM_CORE_TEST_1010'
  Description: 'Test secure service to service call with buffer handling'
  TEST PASSED!
> Executing 'TFM_CORE_TEST_1012'
  Description: 'Test service peripheral access'
  TEST PASSED!
> Executing 'TFM_CORE_TEST_1013'
  Description: 'Test get caller client ID function'
  TEST PASSED!
> Executing 'TFM_CORE_TEST_1014'
  Description: 'Test SPM request function'
  TEST PASSED!
> Executing 'TFM_CORE_TEST_1015'
  Description: 'Test service parameter sanitization'
  TEST PASSED!
> Executing 'TFM_CORE_TEST_1016'
  Description: 'Test outvec write'
  TEST PASSED!
TESTSUITE PASSED!

*** Non-secure test suites summary ***
Test suite 'PSA protected storage NS interface tests (TFM_SST_TEST_1XXX)' has  PASSED
Test suite 'PSA internal trusted storage NS interface tests (TFM_ITS_TEST_1XXX)' has  PASSED
Test suite 'Crypto non-secure interface test (TFM_CRYPTO_TEST_6XXX)' has  PASSED
Test suite 'Initial Attestation Service non-secure interface tests(TFM_ATTEST_TEST_2XXX)' has  PASSED
Test suite 'Platform Service Non-Secure interface tests(TFM_PLATFORM_TEST_2XXX)' has  PASSED
Test suite 'QCBOR regression test(TFM_QCBOR_TEST_7XXX)' has  PASSED
Test suite 'T_COSE regression test(TFM_T_COSE_TEST_8XXX)' has  PASSED
Test suite 'AuditLog non-secure interface test (TFM_AUDIT_TEST_1XXX)' has  PASSED
Test suite 'Core non-secure positive tests (TFM_CORE_TEST_1XXX)' has  PASSED
```

## Docker Image

This image is intended to be run with the `docker-test-images/qemu5` docker
container, or alternatively from the `kevintownsend/lite-qemu5:v1` image on
DockerHub.
