#include "RubyInterpreter.hpp"
#include "embedded_files.hpp"
#include "InitMacros.hxx"

#include <iostream>

#ifndef _MSC_VER
#include <dlfcn.h>
#include <dirent.h>
#else
#include <windows.h>
#endif


extern "C" {
  void Init_EmbeddedScripting(void);
  INIT_DECLARATIONS;
}


int main(int argc, char *argv[])
{
  std::cout << "***** Initializing ruby *****\n";
  ruby_sysinit(&argc, &argv);
  {
    RUBY_INIT_STACK;
    ruby_init();
    Init_EmbeddedScripting();
    INIT_CALLS;
    RB_PROVIDES_CALLS;
  }

  std::cout << "***** Initializing RubyInterpreter Wrapper *****\n";
  std::vector<std::string> paths;
  RubyInterpreter rubyInterpreter(paths);

  std::cout << "***** Shimming Our Kernel::require method *****\n";
  auto embedded_extensions_string = embedded_files::getFileAsString(":/embedded_help.rb");
  rubyInterpreter.evalString(embedded_extensions_string);
  rubyInterpreter.evalString(R"(require 'csv.rb')");


}
