
message(STATUS "Embedding '${INFILE}' as '${OUTNAME}'")

file(READ ${INFILE} FILEDATA HEX)
string(LENGTH ${FILEDATA} STRLEN)
math(EXPR filelen "${STRLEN} / 2")

math(EXPR STRLENEND "${STRLEN} - 1")
set(FILEDATASTR "")
foreach (byte RANGE 0 ${STRLENEND} 2)
  string(SUBSTRING ${FILEDATA} ${byte} 2 bytedata)
  set(FILEDATASTR "${FILEDATASTR} 0x${bytedata},")
endforeach()
math(EXPR EXPECTEDLENGTH "(${filelen} * 6) - 1")
string(SUBSTRING ${FILEDATASTR} 0 ${EXPECTEDLENGTH} FILEDATASTR)

file(APPEND ${EMBED_SOURCE_FILE} "  static const uint8_t embedded_file_${filenum}[] = {\n    ${FILEDATASTR}\n  };\n" )
file(APPEND ${EMBED_SOURCE_FILE} "  static const char *embedded_file_name_${filenum} = \"${OUTNAME}\";\n" )
file(APPEND ${EMBED_SOURCE_FILE} "  static const size_t embedded_file_len_${filenum} = ${filelen};\n" )
