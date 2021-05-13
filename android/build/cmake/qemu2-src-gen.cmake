# Copyright 2018 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
# This contains a set of functions to make working with different targets a lot easier. The idea is that you can now set
# properties that define your lib/executable through variables that follow the following naming conventions
#
if(INCLUDE_QEMU2_SRC_GEN_CMAKE)
  return()
endif()

set(INCLUDE_QEMU2_SRC_GEN_CMAKE 1)

function(generate_trace)
  set(options)
  set(oneValueArgs DEST GROUP FORMAT BACKEND SRC_DIR GENERATED)
  set(multiValueArgs)
  cmake_parse_arguments(trace "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  # Make sure the .c files depend on the .h files, otherwise they might not be
  # generated properly.
  if (${trace_DEST} MATCHES "c$")
    string(REPLACE ".c" ".h" DEPENDENCIES ${trace_DEST})
  endif()
  list(APPEND DEPENDENCIES ${ANDROID_QEMU2_TOP_DIR}/${trace_SRC_DIR}/trace-events)
  add_custom_command(
    OUTPUT ${trace_DEST}
    COMMAND
      python ${ANDROID_QEMU2_TOP_DIR}/scripts/tracetool.py
      --group=${trace_GROUP} --format=${trace_FORMAT} --backends=${trace_BACKEND}
      ${ANDROID_QEMU2_TOP_DIR}/${trace_SRC_DIR}/trace-events ${trace_DEST}
    DEPENDS ${DEPENDENCIES})
  set_source_files_properties(${trace_DEST} PROPERTIES GENERATED TRUE  COMPILE_FLAGS " -I ${ANDROID_QEMU2_TOP_DIR}/${trace_SRC_DIR} -I ${trace_DEST}")
  list(APPEND ${trace_GENERATED} ${trace_DEST})
  set(${trace_GENERATED} ${${trace_GENERATED}} PARENT_SCOPE)
endfunction()

# ~~~
# Generates all tracefiles used by qemu.
#
# ``BACKEND``   The desired tracing backend. Valid backends are:
#               nop, dtrace, ftrace, log, simple, syslog, ust
# ``GENERATED`` The set of sources that were generated.
# ``DEST``      The destination directory of the generated sources.
# ~~~
function(generate_traces)
  set(options)
  set(oneValueArgs GENERATED BACKEND DEST)
  set(multiValueArgs)
  cmake_parse_arguments(traces "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  set(TRACE_SRC "")
  # ~~~
  # This section was autogenerated by running
  # android/scripts/unix/generate-trace-cmake-snippet.sh
    generate_trace(GROUP qapi FORMAT h BACKEND ${traces_BACKEND} SRC_DIR qapi DEST ${traces_DEST}/qapi/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP qapi FORMAT c BACKEND ${traces_BACKEND} SRC_DIR qapi DEST ${traces_DEST}/qapi/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP ui FORMAT h BACKEND ${traces_BACKEND} SRC_DIR ui DEST ${traces_DEST}/ui/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP ui FORMAT c BACKEND ${traces_BACKEND} SRC_DIR ui DEST ${traces_DEST}/ui/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP crypto FORMAT h BACKEND ${traces_BACKEND} SRC_DIR crypto DEST ${traces_DEST}/crypto/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP crypto FORMAT c BACKEND ${traces_BACKEND} SRC_DIR crypto DEST ${traces_DEST}/crypto/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP net FORMAT h BACKEND ${traces_BACKEND} SRC_DIR net DEST ${traces_DEST}/net/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP net FORMAT c BACKEND ${traces_BACKEND} SRC_DIR net DEST ${traces_DEST}/net/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_ide FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/ide DEST ${traces_DEST}/hw/ide/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_ide FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/ide DEST ${traces_DEST}/hw/ide/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_misc FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/misc DEST ${traces_DEST}/hw/misc/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_misc FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/misc DEST ${traces_DEST}/hw/misc/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_misc_macio FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/misc/macio DEST ${traces_DEST}/hw/misc/macio/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_misc_macio FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/misc/macio DEST ${traces_DEST}/hw/misc/macio/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_xen FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/xen DEST ${traces_DEST}/hw/xen/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_xen FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/xen DEST ${traces_DEST}/hw/xen/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_sd FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/sd DEST ${traces_DEST}/hw/sd/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_sd FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/sd DEST ${traces_DEST}/hw/sd/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_pci FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/pci DEST ${traces_DEST}/hw/pci/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_pci FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/pci DEST ${traces_DEST}/hw/pci/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_acpi FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/acpi DEST ${traces_DEST}/hw/acpi/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_acpi FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/acpi DEST ${traces_DEST}/hw/acpi/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_net FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/net DEST ${traces_DEST}/hw/net/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_net FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/net DEST ${traces_DEST}/hw/net/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_char FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/char DEST ${traces_DEST}/hw/char/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_char FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/char DEST ${traces_DEST}/hw/char/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_intc FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/intc DEST ${traces_DEST}/hw/intc/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_intc FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/intc DEST ${traces_DEST}/hw/intc/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_isa FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/isa DEST ${traces_DEST}/hw/isa/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_isa FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/isa DEST ${traces_DEST}/hw/isa/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_virtio FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/virtio DEST ${traces_DEST}/hw/virtio/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_virtio FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/virtio DEST ${traces_DEST}/hw/virtio/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_s390x FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/s390x DEST ${traces_DEST}/hw/s390x/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_s390x FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/s390x DEST ${traces_DEST}/hw/s390x/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_input FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/input DEST ${traces_DEST}/hw/input/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_input FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/input DEST ${traces_DEST}/hw/input/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_tpm FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/tpm DEST ${traces_DEST}/hw/tpm/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_tpm FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/tpm DEST ${traces_DEST}/hw/tpm/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_i386_xen FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/i386/xen DEST ${traces_DEST}/hw/i386/xen/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_i386_xen FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/i386/xen DEST ${traces_DEST}/hw/i386/xen/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_i386 FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/i386 DEST ${traces_DEST}/hw/i386/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_i386 FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/i386 DEST ${traces_DEST}/hw/i386/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_scsi FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/scsi DEST ${traces_DEST}/hw/scsi/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_scsi FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/scsi DEST ${traces_DEST}/hw/scsi/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_hppa FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/hppa DEST ${traces_DEST}/hw/hppa/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_hppa FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/hppa DEST ${traces_DEST}/hw/hppa/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_ppc FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/ppc DEST ${traces_DEST}/hw/ppc/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_ppc FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/ppc DEST ${traces_DEST}/hw/ppc/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_timer FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/timer DEST ${traces_DEST}/hw/timer/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_timer FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/timer DEST ${traces_DEST}/hw/timer/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_vfio FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/vfio DEST ${traces_DEST}/hw/vfio/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_vfio FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/vfio DEST ${traces_DEST}/hw/vfio/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_usb FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/usb DEST ${traces_DEST}/hw/usb/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_usb FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/usb DEST ${traces_DEST}/hw/usb/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_audio FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/audio DEST ${traces_DEST}/hw/audio/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_audio FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/audio DEST ${traces_DEST}/hw/audio/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_rdma_vmw FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/rdma/vmw DEST ${traces_DEST}/hw/rdma/vmw/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_rdma_vmw FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/rdma/vmw DEST ${traces_DEST}/hw/rdma/vmw/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_rdma FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/rdma DEST ${traces_DEST}/hw/rdma/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_rdma FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/rdma DEST ${traces_DEST}/hw/rdma/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_sparc64 FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/sparc64 DEST ${traces_DEST}/hw/sparc64/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_sparc64 FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/sparc64 DEST ${traces_DEST}/hw/sparc64/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_pci_host FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/pci-host DEST ${traces_DEST}/hw/pci-host/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_pci_host FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/pci-host DEST ${traces_DEST}/hw/pci-host/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_dma FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/dma DEST ${traces_DEST}/hw/dma/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_dma FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/dma DEST ${traces_DEST}/hw/dma/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_display FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/display DEST ${traces_DEST}/hw/display/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_display FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/display DEST ${traces_DEST}/hw/display/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_9pfs FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/9pfs DEST ${traces_DEST}/hw/9pfs/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_9pfs FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/9pfs DEST ${traces_DEST}/hw/9pfs/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_arm FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/arm DEST ${traces_DEST}/hw/arm/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_arm FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/arm DEST ${traces_DEST}/hw/arm/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_nvram FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/nvram DEST ${traces_DEST}/hw/nvram/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_nvram FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/nvram DEST ${traces_DEST}/hw/nvram/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_alpha FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/alpha DEST ${traces_DEST}/hw/alpha/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_alpha FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/alpha DEST ${traces_DEST}/hw/alpha/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_sparc FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/sparc DEST ${traces_DEST}/hw/sparc/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_sparc FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/sparc DEST ${traces_DEST}/hw/sparc/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_mem FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/mem DEST ${traces_DEST}/hw/mem/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_mem FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/mem DEST ${traces_DEST}/hw/mem/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_block FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/block DEST ${traces_DEST}/hw/block/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_block FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/block DEST ${traces_DEST}/hw/block/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP hw_block_dataplane FORMAT h BACKEND ${traces_BACKEND} SRC_DIR hw/block/dataplane DEST ${traces_DEST}/hw/block/dataplane/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP hw_block_dataplane FORMAT c BACKEND ${traces_BACKEND} SRC_DIR hw/block/dataplane DEST ${traces_DEST}/hw/block/dataplane/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP util FORMAT h BACKEND ${traces_BACKEND} SRC_DIR util DEST ${traces_DEST}/util/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP util FORMAT c BACKEND ${traces_BACKEND} SRC_DIR util DEST ${traces_DEST}/util/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP target_s390x FORMAT h BACKEND ${traces_BACKEND} SRC_DIR target/s390x DEST ${traces_DEST}/target/s390x/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP target_s390x FORMAT c BACKEND ${traces_BACKEND} SRC_DIR target/s390x DEST ${traces_DEST}/target/s390x/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP target_i386 FORMAT h BACKEND ${traces_BACKEND} SRC_DIR target/i386 DEST ${traces_DEST}/target/i386/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP target_i386 FORMAT c BACKEND ${traces_BACKEND} SRC_DIR target/i386 DEST ${traces_DEST}/target/i386/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP target_ppc FORMAT h BACKEND ${traces_BACKEND} SRC_DIR target/ppc DEST ${traces_DEST}/target/ppc/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP target_ppc FORMAT c BACKEND ${traces_BACKEND} SRC_DIR target/ppc DEST ${traces_DEST}/target/ppc/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP target_mips FORMAT h BACKEND ${traces_BACKEND} SRC_DIR target/mips DEST ${traces_DEST}/target/mips/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP target_mips FORMAT c BACKEND ${traces_BACKEND} SRC_DIR target/mips DEST ${traces_DEST}/target/mips/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP target_arm FORMAT h BACKEND ${traces_BACKEND} SRC_DIR target/arm DEST ${traces_DEST}/target/arm/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP target_arm FORMAT c BACKEND ${traces_BACKEND} SRC_DIR target/arm DEST ${traces_DEST}/target/arm/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP target_sparc FORMAT h BACKEND ${traces_BACKEND} SRC_DIR target/sparc DEST ${traces_DEST}/target/sparc/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP target_sparc FORMAT c BACKEND ${traces_BACKEND} SRC_DIR target/sparc DEST ${traces_DEST}/target/sparc/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP scsi FORMAT h BACKEND ${traces_BACKEND} SRC_DIR scsi DEST ${traces_DEST}/scsi/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP scsi FORMAT c BACKEND ${traces_BACKEND} SRC_DIR scsi DEST ${traces_DEST}/scsi/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP io FORMAT h BACKEND ${traces_BACKEND} SRC_DIR io DEST ${traces_DEST}/io/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP io FORMAT c BACKEND ${traces_BACKEND} SRC_DIR io DEST ${traces_DEST}/io/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT c BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/trace-root.c GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT h BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/trace-root.h GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT tcg-helper-wrapper-h BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/trace/generated-helpers-wrappers.h GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT tcg-helper-c BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/trace/generated-helpers.c GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT tcg-helper-h BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/trace/generated-helpers.h GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT tcg-h BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/trace/generated-tcg-tracers.h GENERATED TRACE_SRC)
    generate_trace(GROUP chardev FORMAT h BACKEND ${traces_BACKEND} SRC_DIR chardev DEST ${traces_DEST}/chardev/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP chardev FORMAT c BACKEND ${traces_BACKEND} SRC_DIR chardev DEST ${traces_DEST}/chardev/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP accel_tcg FORMAT h BACKEND ${traces_BACKEND} SRC_DIR accel/tcg DEST ${traces_DEST}/accel/tcg/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP accel_tcg FORMAT c BACKEND ${traces_BACKEND} SRC_DIR accel/tcg DEST ${traces_DEST}/accel/tcg/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP accel_kvm FORMAT h BACKEND ${traces_BACKEND} SRC_DIR accel/kvm DEST ${traces_DEST}/accel/kvm/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP accel_kvm FORMAT c BACKEND ${traces_BACKEND} SRC_DIR accel/kvm DEST ${traces_DEST}/accel/kvm/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP audio FORMAT h BACKEND ${traces_BACKEND} SRC_DIR audio DEST ${traces_DEST}/audio/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP audio FORMAT c BACKEND ${traces_BACKEND} SRC_DIR audio DEST ${traces_DEST}/audio/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP linux_user FORMAT h BACKEND ${traces_BACKEND} SRC_DIR linux-user DEST ${traces_DEST}/linux-user/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP linux_user FORMAT c BACKEND ${traces_BACKEND} SRC_DIR linux-user DEST ${traces_DEST}/linux-user/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP qom FORMAT h BACKEND ${traces_BACKEND} SRC_DIR qom DEST ${traces_DEST}/qom/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP qom FORMAT c BACKEND ${traces_BACKEND} SRC_DIR qom DEST ${traces_DEST}/qom/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP nbd FORMAT h BACKEND ${traces_BACKEND} SRC_DIR nbd DEST ${traces_DEST}/nbd/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP nbd FORMAT c BACKEND ${traces_BACKEND} SRC_DIR nbd DEST ${traces_DEST}/nbd/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP migration FORMAT h BACKEND ${traces_BACKEND} SRC_DIR migration DEST ${traces_DEST}/migration/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP migration FORMAT c BACKEND ${traces_BACKEND} SRC_DIR migration DEST ${traces_DEST}/migration/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP block FORMAT h BACKEND ${traces_BACKEND} SRC_DIR block DEST ${traces_DEST}/block/trace.h GENERATED TRACE_SRC)
    generate_trace(GROUP block FORMAT c BACKEND ${traces_BACKEND} SRC_DIR block DEST ${traces_DEST}/block/trace.c GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT tcg-helper-c BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/target/i386/generated-helpers.c GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT tcg-helper-h BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/target/i386/generated-helpers.h GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT tcg-helper-c BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/target/aarch64/generated-helpers.c GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT tcg-helper-h BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/target/aarch64/generated-helpers.h GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT tcg-helper-c BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/target/arm/generated-helpers.c GENERATED TRACE_SRC)
    generate_trace(GROUP root FORMAT tcg-helper-h BACKEND ${traces_BACKEND} SRC_DIR . DEST ${traces_DEST}/target/arm/generated-helpers.h GENERATED TRACE_SRC)
  set(${traces_GENERATED} ${TRACE_SRC} PARENT_SCOPE)
endfunction()

#~~~
# Generates all the qemu2 sources. This will set the following 2 variables:
#
# ``qemu2-generated_trace_sources``  All the generated sources
# ``ANDROID_AUTOGEN``    Prefix used by the compile settings.
#
# ``TRACE_BACKEND``   The desired tracing backend. Valid backends are:
#               nop, dtrace, ftrace, log, simple, syslog, ust
# ``DEST``      The destination directory of the generated sources.
#~~~
function(generate_qemu2_sources)
  set(options)
  set(oneValueArgs TRACE_BACKEND DEST)
  set(multiValueArgs)
  cmake_parse_arguments(gen "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  set(AUTOGEN "${gen_DEST}/qemu2-auto-generated")
  file(MAKE_DIRECTORY ${gen_DEST})
  file(COPY qemu2-auto-generated DESTINATION ${gen_DEST})
  generate_traces(BACKEND ${gen_TRACE_BACKEND} GENERATED trace_src DEST ${AUTOGEN})
  set(ANDROID_AUTOGEN ${AUTOGEN} PARENT_SCOPE)
  set(qemu2-generated_trace_sources ${trace_src} PARENT_SCOPE)
endfunction()
