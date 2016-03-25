cmake_minimum_required (VERSION 2.8.6)

project (EmbeddedScripting CXX)

find_program(SWIG_EXECUTABLE NAMES swig3.0 swig2.0 swig HINTS "c:/swigwin-3.0.8")
find_package(SWIG REQUIRED)

IF (APPLE)
   find_library(COREFOUNDATION_LIBRARY CoreFoundation )
ENDIF (APPLE)

if ("${MSVC_VERSION}" STREQUAL "1900")
  add_definitions(/DHAVE_STRUCT_TIMESPEC=1)
endif()

find_package(Ruby 1.9 REQUIRED)


file(GLOB EXTENSION_LIBS "${RUBY_POSSIBLE_LIB_DIR}/../../ext/**/*.a")

set(LIBS 
  bigdecimal
  continuation
  coverage
  date_core
  dbm
  digest
  etc
  fcntl
  fiber
  ##fiddle
  ##nkf
  objspace
  pathname
  ##psych
  pty
  ##readline
  ripper
  sdbm
  socket
  stringio
  strscan
  syslog
  thread
  ##tcltklib
)

set(INIT_CALLS "")
set(INIT_DECLARATIONS "")
foreach(LIB ${EXTENSION_LIBS})
  get_filename_component(LIB_NAME ${LIB} NAME_WE)
  list (FIND LIBS "${LIB_NAME}" _index)
  if( ${_index} GREATER -1 )
    set(INIT_CALLS "${INIT_CALLS}  Init_${LIB_NAME}();\\\n" )
    set(INIT_DECLARATIONS "${INIT_DECLARATIONS}  void Init_${LIB_NAME}();\\\n" )
  endif()
endforeach()

configure_file("InitMacros.hxx.in" "InitMacros.hxx")

function(embed_files )
  #set(OUTFILE "${CMAKE_BINARY_DIR}/embedded_files.cpp")
  #file(WRITE  ${OUTFILE}  "#include <embedded_files.hpp>\n ")
  #file(APPEND ${OUTFILE}  "namespace embedded_files {\n ")

  math(EXPR ARGCEND "${ARGC} - 1")
  math(EXPR NUMFILES "${ARGC} / 2")
  math(EXPR MAXFILECOUNT "${NUMFILES} - 1")

  #file(APPEND ${OUTFILE} "  static const size_t embedded_file_count = ${NUMFILES};\n" )

  foreach (arg RANGE 0 ${ARGCEND} 2)
    # INFILE is the path to the file to embed into the executable
    list(GET ARGV ${arg} INFILE)
    math(EXPR argplus1 "${arg} + 1")
    math(EXPR filenum "${arg} / 2")
    # OUTNAME is the path to the embedded file
    # this is the path used to reference the file inside the executable
    list(GET ARGV ${argplus1} OUTNAME)

    get_filename_component(BASE_PATH ${OUTNAME} DIRECTORY)
    get_filename_component(BASE_FILENAME ${OUTNAME} NAME_WE)
    get_filename_component(EXTENSION ${OUTNAME} EXT)

    # EMBED_SOURCE_FILE is the fully qualified path to a cxx file with the embedded data
    set(EMBED_SOURCE_FILE "${CMAKE_BINARY_DIR}/embedded_files/${BASE_PATH}/${BASE_FILENAME}_${EXTENSION}.cxx")
    list(APPEND EMBED_SOURCE_FILES ${EMBED_SOURCE_FILE})    

    add_custom_command(OUTPUT ${EMBED_SOURCE_FILE}
      COMMAND ${CMAKE_COMMAND} -DEMBED_SOURCE_FILE:String=${EMBED_SOURCE_FILE} -DINFILE:String=${INFILE} -DOUTNAME:String=${OUTNAME} -P "${CMAKE_SOURCE_DIR}/GenerateEmeddedSource.cmake"
      DEPENDS ${INFILE}
    )
    set(EMBED_SOURCE_FILES ${EMBED_SOURCE_FILES} PARENT_SCOPE)
  endforeach()

  ## file names
  #file(APPEND ${OUTFILE} "  static const char *embedded_file_names[] = {\n")
  #foreach (arg RANGE 0 ${MAXFILECOUNT})
  #  file(APPEND ${OUTFILE} "    embedded_file_name_${arg}")
  #  if (NOT arg EQUAL MAXFILECOUNT)
  #    file(APPEND ${OUTFILE} ",")
  #  endif()
  #  file(APPEND ${OUTFILE} "\n")
  #endforeach()
  #file(APPEND ${OUTFILE} "  };\n")

  ## lengths
  #file(APPEND ${OUTFILE} "  static const size_t embedded_file_lens[] = {\n")
  #foreach (arg RANGE 0 ${MAXFILECOUNT})
  #  file(APPEND ${OUTFILE} "    embedded_file_len_${arg}")
  #  if (NOT arg EQUAL MAXFILECOUNT)
  #    file(APPEND ${OUTFILE} ",")
  #  endif()
  #  file(APPEND ${OUTFILE} "\n")
  #endforeach()
  #file(APPEND ${OUTFILE} "  };\n")

  ## datas
  #file(APPEND ${OUTFILE} "  static const uint8_t *embedded_files[] = {\n")
  #foreach (arg RANGE 0 ${MAXFILECOUNT})
  #  file(APPEND ${OUTFILE} "    embedded_file_${arg}")
  #  if (NOT arg EQUAL MAXFILECOUNT)
  #    file(APPEND ${OUTFILE} ",")
  #  endif()
  #  file(APPEND ${OUTFILE} "\n")
  #endforeach()
  #file(APPEND ${OUTFILE} "  };\n")

  #file(APPEND ${OUTFILE} "    std::map<std::string, std::pair<size_t, const uint8_t *>> files()\n")
  #file(APPEND ${OUTFILE} "    {\n")
  #file(APPEND ${OUTFILE} "      std::map<std::string, std::pair<size_t, const uint8_t *>> fs;\n")
  #file(APPEND ${OUTFILE} "      for (size_t i = 0; i < embedded_file_count; ++i) {\n")
  #file(APPEND ${OUTFILE} "        fs.insert(std::make_pair(std::string(embedded_file_names[i]), \n")
  #file(APPEND ${OUTFILE} "                                 std::make_pair(embedded_file_lens[i],\n")
  #file(APPEND ${OUTFILE} "                                                embedded_files[i])));\n")
  #file(APPEND ${OUTFILE} "      }\n")
  #file(APPEND ${OUTFILE} "      return fs;\n")
  #file(APPEND ${OUTFILE} "    }\n")


  #file(APPEND ${CMAKE_BINARY_DIR}/embedded_files.cpp "} //close namespace")
endfunction()

file(GLOB_RECURSE  EXTENSION_RB  FOLLOW_SYMLINKS "${RUBY_POSSIBLE_LIB_DIR}/**/*.rb")

foreach( _FILE ${EXTENSION_RB} )
  file(RELATIVE_PATH LOCATION ${RUBY_POSSIBLE_LIB_DIR} ${_FILE})
  list(APPEND EMBED_RB ${_FILE} ${LOCATION})
endforeach()

embed_files(
  "${CMAKE_CURRENT_SOURCE_DIR}/test.rb" "myvfs/test.rb"
  "${CMAKE_CURRENT_SOURCE_DIR}/test2.rb" "myvfs/test2.rb"
  "${CMAKE_CURRENT_SOURCE_DIR}/test3.rb" "extracted/test3.rb"
  ${EMBED_RB} 
  )


set(BUILD_SHARED_LIBS OFF)

set_source_files_properties(EmbeddedScripting.i
  PROPERTIES CPLUSPLUS true
  )

if (UNIX)
  set(CMAKE_CXX_FLAGS "-std=c++11 -Wall -Wextra -pthread ")

  option(ENABLE_ADDRESS_SANITIZER "Enable address sanitizer testing in gcc/clang" FALSE)
  if(ENABLE_ADDRESS_SANITIZER)
    add_definitions(-fsanitize=address -g)
    set(LINKER_FLAGS "${LINKER_FLAGS} -fsanitize=address")
  endif()

  option(ENABLE_MEMORY_SANITIZER "Enable memory sanitizer testing in gcc/clang" FALSE)
  if(ENABLE_MEMORY_SANITIZER)
    add_definitions(-fsanitize=memory -g)
    set(LINKER_FLAGS "${LINKER_FLAGS} -fsanitize=memory")
  endif()
endif()

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LINKER_FLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${LINKER_FLAGS}")
set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${LINKER_FLAGS}")

include_directories(${RUBY_INCLUDE_DIR} ${RUBY_CONFIG_INCLUDE_DIR} ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR} )

add_custom_command(
  OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/SWIGRubyRuntime.hxx"
  COMMAND "${SWIG_EXECUTABLE}"
          "-ruby"
          -external-runtime "${CMAKE_CURRENT_BINARY_DIR}/SWIGRubyRuntime.hxx"
)

add_custom_command(
  OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/EmbeddedScriptingRUBY_wrap.cxx"
  COMMAND "${SWIG_EXECUTABLE}"
          "-ruby"
          "-c++"
          -o "${CMAKE_CURRENT_BINARY_DIR}/EmbeddedScriptingRUBY_wrap.cxx"
          "${CMAKE_CURRENT_SOURCE_DIR}/EmbeddedScripting.i"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/EmbeddedScripting.i"
          "embedded_files.hpp"
)

set_source_files_properties(${EMBED_SOURCE_FILES} PROPERTIES HEADER_FILE_ONLY TRUE)

add_executable(EmbeddedScripting
 "${CMAKE_CURRENT_BINARY_DIR}/SWIGRubyRuntime.hxx"
 main.cpp
 RubyException.hpp
 RubyInterpreter.hpp
 embedded_files.hpp
 "${CMAKE_CURRENT_BINARY_DIR}/embedded_files.cpp"
 "${CMAKE_CURRENT_BINARY_DIR}/EmbeddedScriptingRUBY_wrap.cxx"
 ${EMBED_SOURCE_FILES} 
 )


if (UNIX AND NOT APPLE)
  target_link_libraries(EmbeddedScripting ${RUBY_LIBRARY}  "dl" "crypt")
else()
  target_link_libraries(EmbeddedScripting ${RUBY_LIBRARY} )
endif()

if( APPLE )
  target_link_libraries(EmbeddedScripting ${COREFOUNDATION_LIBRARY} )
endif()

target_link_libraries(EmbeddedScripting ${EXTENSION_LIBS} )


