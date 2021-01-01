#
# module: GlobalArrays.cmake
# author: Bruce Palmer
# description: Define utility functions.
# 
# DISCLAIMER
#
# This material was prepared as an account of work sponsored by an
# agency of the United States Government.  Neither the United States
# Government nor the United States Department of Energy, nor Battelle,
# nor any of their employees, MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR
# ASSUMES ANY LEGAL LIABILITY OR RESPONSIBILITY FOR THE ACCURACY,
# COMPLETENESS, OR USEFULNESS OF ANY INFORMATION, APPARATUS, PRODUCT,
# SOFTWARE, OR PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE WOULD NOT
# INFRINGE PRIVATELY OWNED RIGHTS.
#
#
# ACKNOWLEDGMENT
#
# This software and its documentation were produced with United States
# Government support under Contract Number DE-AC06-76RLO-1830 awarded by
# the United States Department of Energy.  The United States Government
# retains a paid-up non-exclusive, irrevocable worldwide license to
# reproduce, prepare derivative works, perform publicly and display
# publicly by or for the US Government, including the right to
# distribute to other US Government contractors.
#


function(ga_set_blasroot __blasvendor __blasvar)
  if("${BLAS_VENDOR}" STREQUAL "${__blasvendor}")
    set(__ebv_exists FALSE)
    ga_path_exists(${__blasvar} __bv_exists)
    if (DEFINED ENV{${__blasvar}})
      set(__eblasvar $ENV{${__blasvar}})
      ga_path_exists(__eblasvar __ebv_exists)
      if(__ebv_exists)
        set(${__blasvar} ${__eblasvar} PARENT_SCOPE)
      endif()
    endif()
    if(NOT __bv_exists AND NOT __ebv_exists)
      message(FATAL_ERROR "Could not find the following ${__blasvar} path: ${__eblasvar} ${${__blasvar}}")
    endif()
  endif()
endfunction()

#Check if provided paths are valid and export
if (ENABLE_BLAS)
  ga_set_blasroot("IntelMKL" MKLROOT)
  ga_set_blasroot("IBMESSL"  ESSLROOT)
  ga_set_blasroot("BLIS"     BLISROOT)
  ga_set_blasroot("ReferenceBLAS"   ReferenceBLASROOT)
  ga_set_blasroot("ReferenceLAPACK" ReferenceLAPACKROOT)
  ga_set_blasroot("ReferenceScaLAPACK" ReferenceScaLAPACKROOT)
  if (ENABLE_DPCPP)
    ga_set_blasroot("IntelMKL" DPCPP_ROOT)
  endif()
endif()

# check for numerical libraries. These should set variables BLAS_FOUND and
# LAPACK_FOUND
set(GA_BLAS_ILP64 OFF)
if (ENABLE_BLAS)
    set(LINALG_PREFER_STATIC ON)
    if(BUILD_SHARED_LIBS)
      set(LINALG_PREFER_STATIC OFF)
    endif()
    set(${BLAS_VENDOR}_PREFERS_STATIC     ${LINALG_PREFER_STATIC})
    set(ReferenceLAPACK_PREFERS_STATIC    ${LINALG_PREFER_STATIC})
    set(ReferenceScaLAPACK_PREFERS_STATIC ${LINALG_PREFER_STATIC})

    set(BLAS_SIZE 4)
    set(${BLAS_VENDOR}_THREAD_LAYER   ${LINALG_THREAD_LAYER})
    set(BLAS_REQUIRED_COMPONENTS      ${LINALG_REQUIRED_COMPONENTS})
    set(LAPACK_REQUIRED_COMPONENTS    ${LINALG_REQUIRED_COMPONENTS})
    set(ScaLAPACK_REQUIRED_COMPONENTS ${LINALG_REQUIRED_COMPONENTS})

    if( "ilp64" IN_LIST LINALG_REQUIRED_COMPONENTS )
      set(BLAS_SIZE 8)
      set(GA_BLAS_ILP64 ON)
      if(ENABLE_SCALAPACK AND NOT "${BLAS_VENDOR}" STREQUAL "IntelMKL")
        message( FATAL_ERROR "ReferenceScaLAPACK with ILP64 interface is currently not supported. Please unset the LINALG_REQUIRED_COMPONENTS option." )
      endif()
    endif()

    if(ENABLE_SCALAPACK)
      find_package(ScaLAPACK)
      if (ScaLAPACK_FOUND)
        set(HAVE_SCALAPACK 1)
      else()
        message(FATAL_ERROR "ENABLE_SCALAPACK=ON, but a ScaLAPACK library was not found")
      endif()
    endif()

    find_package(LAPACK)
    if (LAPACK_FOUND)
      set(HAVE_LAPACK 1)
    else()
      message(FATAL_ERROR "ENABLE_BLAS=ON, but a LAPACK library was not found")
    endif()

    find_package(BLAS)
    if (BLAS_FOUND)
      set(HAVE_BLAS 1)
    else()
      message(FATAL_ERROR "ENABLE_BLAS=ON, but a BLAS library was not found")
    endif()

else()
    set(HAVE_BLAS 0)
    set(HAVE_LAPACK 0)
    set(HAVE_SCALAPACK 0)
endif()

if(ENABLE_DPCPP)
  set(USE_DPCPP ON)
  find_package(IntelSYCL REQUIRED)
  set(Intel_SYCL_TARGET Intel::SYCL)
endif()

if (ENABLE_SCALAPACK)
  set(SCALAPACK_I8 OFF)
  if( "ilp64" IN_LIST LINALG_REQUIRED_COMPONENTS )
    set(SCALAPACK_I8 ON)
  endif()

  # add_definitions(-DHAVE_SCALAPACK)
  if (SCALAPACK_I8)
    add_definitions(-DSCALAPACK_I8)
  endif()
endif()
if (ENABLE_EISPACK)
  add_definitions(-DENABLE_EISPACK)
endif()
# if (ENABLE_FORTRAN)
#   add_definitions(-DENABLE_F77)
# endif()

message(STATUS "HAVE_BLAS: ${HAVE_BLAS}")
message(STATUS "HAVE_LAPACK: ${HAVE_LAPACK}")
message(STATUS "HAVE_SCALAPACK: ${HAVE_SCALAPACK}")

set(linalg_lib )

if (HAVE_BLAS)
  if("${BLAS_VENDOR}" STREQUAL "IntelMKL")
    set(BLA_VENDOR_MKL ON )
    set(BLA_LAPACK_INT       "MKL_INT" )
    set(BLA_LAPACK_COMPLEX8  "MKL_Complex8" )
    set(BLA_LAPACK_COMPLEX16 "MKL_Complex16" )
  elseif("${BLAS_VENDOR}" STREQUAL "IBMESSL")
    set(BLA_VENDOR_ESSL ON)
    set(BLA_LAPACK_INT "int32_t")
    if(GA_BLAS_ILP64)
      set(BLA_LAPACK_INT "int64_t")
    endif()
    set(BLA_LAPACK_COMPLEX8  "std::complex<float>")
    set(BLA_LAPACK_COMPLEX16 "std::complex<double>")
  elseif("${BLAS_VENDOR}" STREQUAL "BLIS")
    set(USE_BLIS ON)
    set(BLA_VENDOR_BLIS ON)
    set(BLA_LAPACK_INT "int32_t")
    if(GA_BLAS_ILP64)
      set(BLA_LAPACK_INT "int64_t")
    endif()
    set(BLA_LAPACK_COMPLEX8  "std::complex<float>")
    set(BLA_LAPACK_COMPLEX16 "std::complex<double>")
  endif()

  CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/ga_linalg.h.in
                  ${CMAKE_CURRENT_BINARY_DIR}/ga_linalg.h )
                  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/ga_linalg.h
                  DESTINATION include/ga
  )

  list(APPEND linalg_lib BLAS::BLAS)
  message(STATUS "BLAS_LIBRARIES: ${BLAS_LIBRARIES}")
  if(ENABLE_DPCPP)
    list(APPEND linalg_lib ${Intel_SYCL_TARGET})
    message(STATUS "SYCL_LIBRARIES: ${Intel_SYCL_TARGET}")
  endif()
endif()

if (HAVE_LAPACK)
  list(APPEND linalg_lib LAPACK::LAPACK)
  message(STATUS "LAPACK_LIBRARIES: ${LAPACK_LIBRARIES}")
endif()

if (HAVE_SCALAPACK)
  list(APPEND linalg_lib ScaLAPACK::ScaLAPACK)
  message(STATUS "ScaLAPACK_LIBRARIES: ${ScaLAPACK_LIBRARIES}")
endif()