//
// Copyright (C) 2012 Karl Wette
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with with program; see the file COPYING. If not, write to the
// Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
// MA  02111-1307  USA
//

#include <list>
#include <set>

#include <octave/oct.h>
#if OCTAVE_VERSION_HEX >= 0x040200
#include <octave/interpreter.h>
#else
#include <octave/toplev.h>
#endif
#include <octave/dynamic-ld.h>
#include <octave/ov-usr-fcn.h>
#include <octave/pt-all.h>
#include <octave/Cell.h>

#if OCTAVE_VERSION_HEX <= 0x030204
#define octave_map Octave_map
#endif

#if OCTAVE_VERSION_HEX >= 0x040400
using namespace octave;
#define tree_argument_list octave::tree_argument_list
#endif

// Walker for Octave parse tree which finds function
// names referred to in the parse tree, and stores them
class
OCTINTERP_API
dependency_walker : public tree_walker
{
public:

  std::list<octave_function*> stack;

  octave_map functions;

  Cell exclude;

  std::set<std::string> extra_files;

#if OCTAVE_VERSION_HEX >= 0x040400
  octave::interpreter& interp;

  dependency_walker(octave::interpreter& interp0, const Cell& exclude0)
    : functions(dim_vector(1,1)), exclude(exclude0), interp(interp0)
  { }

#else

  dependency_walker(const Cell& exclude0)
    : functions(dim_vector(1,1)), exclude(exclude0)
  { }

#endif

  ~dependency_walker(void) { }

  // Check if the given string is a function name, and
  // that the function's file name is not excluded; if so,
  // add to map and walk function for further dependencies
  void walk_function(const std::string& n) {
    if (!functions.contains(n)) {
      octave_value v;
      {
#if OCTAVE_VERSION_HEX >= 0x040400
        octave::symbol_table& symtab = interp.get_symbol_table();
        octave::symbol_scope curr_scope = symtab.current_scope();
        octave::symbol_scope fcn_scope = stack.empty() ? curr_scope : stack.back()->scope();
        symtab.set_scope(fcn_scope);
        v = symtab.find_function(n);
#else
#if OCTAVE_VERSION_HEX >= 0x040200
        octave::unwind_protect frame;
#else
        unwind_protect frame;
#endif
        symbol_table::scope_id curr_scope = symbol_table::current_scope();
        frame.add_fcn(symbol_table::set_scope, curr_scope);
        symbol_table::scope_id fcn_scope = stack.empty() ? curr_scope : stack.back()->scope();
        symbol_table::set_scope(fcn_scope);
        v = symbol_table::find_function(n);
#endif
      }
      if (v.is_function() && !v.is_builtin_function()) {
        octave_function *f = v.function_value();
        const std::string fn = f->fcn_file_name();
        for (octave_idx_type j = 0; j < exclude.numel(); ++j) {
          const std::string e = exclude(j).string_value();
          if (fn.substr(0, e.length()) == e) {
            return;
          }
        }
        functions.contents(n) = Cell(octave_value(fn));
        stack.push_back(f);
        f->accept(*this);
        stack.pop_back();
      }
    }
  }

  void visit_anon_fcn_handle(tree_anon_fcn_handle& t) {
    if (t.parameter_list()) {
      t.parameter_list()->accept(*this);
    }
#if OCTAVE_VERSION_HEX < 0x040400
    if (t.body()) {
      t.body()->accept(*this);
    }
#endif
  }

  void visit_argument_list(tree_argument_list& t) {
    for (tree_argument_list::iterator i = t.begin(); i != t.end(); ++i) {
      if (*i) {
        (*i)->accept(*this);
      }
    }
  }

  void visit_binary_expression(tree_binary_expression& t) {
    if (t.lhs()) {
      t.lhs()->accept(*this);
    }
    if (t.rhs()) {
      t.rhs()->accept(*this);
    }
  }

  void visit_break_command(tree_break_command&) { }

  void visit_colon_expression(tree_colon_expression& t) {
    if (t.base()) {
      t.base()->accept(*this);
    }
    if (t.increment()) {
      t.increment()->accept(*this);
    }
    if (t.limit()) {
      t.limit()->accept(*this);
    }
  }

  void visit_continue_command(tree_continue_command&) { }

#if OCTAVE_VERSION_HEX < 0x040400
  void visit_global_command(tree_global_command& t) {
    if (t.initializer_list()) {
      t.initializer_list()->accept(*this);
    }
  }
#endif

#if OCTAVE_VERSION_HEX < 0x030800
  void visit_static_command(tree_static_command& t) {
    if (t.initializer_list()) {
      t.initializer_list()->accept(*this);
    }
  }
#elif OCTAVE_VERSION_HEX < 0x040400
  void visit_persistent_command(tree_persistent_command& t) {
    if (t.initializer_list()) {
      t.initializer_list()->accept(*this);
    }
  }
#endif

  void visit_decl_elt(tree_decl_elt& t) {
    if (t.ident()) {
      t.ident()->accept(*this);
    }
    if (t.expression()) {
      t.expression()->accept(*this);
    }
  }

  void visit_decl_init_list(tree_decl_init_list& t) {
    for (tree_decl_init_list::iterator i = t.begin(); i != t.end(); ++i) {
      if (*i) {
        (*i)->accept(*this);
      }
    }
  }

#if OCTAVE_VERSION_HEX >= 0x040400
  void visit_decl_command(tree_decl_command& t) {
    if (t.initializer_list()) {
      t.initializer_list()->accept(*this);
    }
  }
#endif

  void visit_simple_for_command(tree_simple_for_command& t) {
    if (t.left_hand_side()) {
      t.left_hand_side()->accept(*this);
    }
    if (t.control_expr()) {
      t.control_expr()->accept(*this);
    }
    if (t.body()) {
      t.body()->accept(*this);
    }
  }

  void visit_complex_for_command(tree_complex_for_command& t) {
    if (t.left_hand_side()) {
      t.left_hand_side()->accept(*this);
    }
    if (t.control_expr()) {
      t.control_expr()->accept(*this);
    }
    if (t.body()) {
      t.body()->accept(*this);
    }
  }

  void visit_octave_user_script(octave_user_script& t) {
    if (t.body()) {
      t.body()->accept(*this);
    }
  }

  void visit_octave_user_function(octave_user_function& t) {
    if (t.name().compare("__depends_extra_files__") == 0) {
#if OCTAVE_VERSION_HEX >= 0x040400
      octave_value_list files = t.do_index_op(octave_value());
#else
      octave_value_list files = t.do_multi_index_op(1, octave_value());
#endif
      for (octave_idx_type i = 0; i < files.length(); ++i) {
        std::string file = files(i).string_value();
        if (file.length() > 0) {
          extra_files.insert(file);
        }
      }
    }
    if (t.body()) {
      t.body()->accept(*this);
    }
  }

  void visit_function_def(tree_function_def& t) {
    octave_value v = t.function();
    octave_function *f = v.function_value();
    if (f) {
      f->accept(*this);
    }
  }

  void visit_identifier(tree_identifier& t) {
    walk_function(t.name());
  }

  void visit_if_clause(tree_if_clause& t) {
    if (t.condition()) {
      t.condition()->accept(*this);
    }
    if (t.commands()) {
      t.commands()->accept(*this);
    }
  }

  void visit_if_command(tree_if_command& t) {
    if (t.cmd_list()) {
      t.cmd_list()->accept(*this);
    }
  }

  void visit_if_command_list(tree_if_command_list& t) {
    for (tree_if_command_list::iterator i = t.begin(); i != t.end(); ++i) {
      if (*i) {
        (*i)->accept(*this);
      }
    }
  }

  void visit_index_expression(tree_index_expression& t) {
    if (t.expression()) {
      t.expression()->accept(*this);
    }
    std::list<tree_argument_list *> l = t.arg_lists();
    std::list<tree_argument_list *>::iterator p = l.begin();
    std::string s = t.type_tags();
    for (size_t i = 0; i < s.length(); ++i) {
      switch (s[i]) {
      case '(':
      case '{':
        if (*p) {
          (*p)->accept(*this);
        }
        break;
      default:
        break;
      }
      ++p;
    }
  }

  void visit_matrix(tree_matrix& t) {
    for (tree_matrix::iterator i = t.begin(); i != t.end(); ++i) {
      if (*i) {
        (*i)->accept(*this);
      }
    }
  }

  void visit_cell(tree_cell& t) {
    for (tree_cell::iterator i = t.begin(); i != t.end(); ++i) {
      if (*i) {
        (*i)->accept(*this);
      }
    }
  }

  void visit_multi_assignment(tree_multi_assignment& t) {
    if (t.left_hand_side()) {
      t.left_hand_side()->accept(*this);
    }
    if (t.right_hand_side()) {
      t.right_hand_side()->accept(*this);
    }
  }

  void visit_no_op_command(tree_no_op_command&) { }

  void visit_constant(tree_constant& t) { }

  void visit_fcn_handle(tree_fcn_handle& t) {
    walk_function(t.name());
  }

#if OCTAVE_VERSION_HEX >= 0x040000
  void visit_funcall(tree_funcall& t) {
    walk_function(t.name());
  }
#endif

  void visit_parameter_list(tree_parameter_list& t) {
    for (tree_parameter_list::iterator i = t.begin(); i != t.end(); ++i) {
      if (*i) {
        (*i)->accept(*this);
      }
    }
  }

  void visit_postfix_expression(tree_postfix_expression& t) {
    if (t.operand()) {
      t.operand()->accept(*this);
    }
  }

  void visit_prefix_expression(tree_prefix_expression& t) {
    if (t.operand()) {
      t.operand()->accept(*this);
    }
  }

  void visit_return_command(tree_return_command&) { }

  void visit_return_list(tree_return_list& t) {
    for (tree_return_list::iterator i = t.begin(); i != t.end(); ++i) {
      if (*i) {
        (*i)->accept(*this);
      }
    }
  }

  void visit_simple_assignment(tree_simple_assignment& t) {
    if (t.left_hand_side()) {
      t.left_hand_side()->accept(*this);
    }
    if (t.right_hand_side()) {
      t.right_hand_side()->accept(*this);
    }
  }

  void visit_statement(tree_statement& t) {
    if (t.command()) {
      t.command()->accept(*this);
    }
    if (t.expression()) {
      t.expression()->accept(*this);
    }
  }

  void visit_statement_list(tree_statement_list& t) {
    for (tree_statement_list::iterator i = t.begin(); i != t.end(); ++i) {
      if (*i) {
        (*i)->accept(*this);
      }
    }
  }

  void visit_switch_case(tree_switch_case& t) {
    if (t.case_label()) {
      t.case_label()->accept(*this);
    }
    if (t.commands()) {
      t.commands()->accept(*this);
    }
  }

  void visit_switch_case_list(tree_switch_case_list& t) {
    for (tree_switch_case_list::iterator i = t.begin(); i != t.end(); ++i) {
      if (*i) {
        (*i)->accept(*this);
      }
    }
  }

  void visit_switch_command(tree_switch_command& t) {
    if (t.switch_value()) {
      t.switch_value()->accept(*this);
    }
    if (t.case_list()) {
      t.case_list()->accept(*this);
    }
  }

  void visit_try_catch_command(tree_try_catch_command& t) {
    if (t.body()) {
      t.body()->accept(*this);
    }
    if (t.cleanup()) {
      t.cleanup()->accept(*this);
    }
  }

  void visit_unwind_protect_command(tree_unwind_protect_command& t) {
    if (t.body()) {
      t.body()->accept(*this);
    }
    if (t.cleanup()) {
      t.cleanup()->accept(*this);
    }
  }

  void visit_while_command(tree_while_command& t) {
    if (t.condition()) {
      t.condition()->accept(*this);
    }
    if (t.body()) {
      t.body()->accept(*this);
    }
  }

  void visit_do_until_command(tree_do_until_command& t) {
    if (t.condition()) {
      t.condition()->accept(*this);
    }
    if (t.body()) {
      t.body()->accept(*this);
    }
  }

};

static const char *const depends_usage = "-*- texinfo -*- \n\
@deftypefn {Loadable Function} {[@var{deps},@var{extras}] =} depends(@var{function}, @dots{})\n\
@deftypefnx{Loadable Function} {[@var{deps},@var{extras}] =} depends(@var{exclude}, @var{function}, @dots{})\n\
\n\n\
Returns a struct containing the names (keys) and filenames (values) of functions required by the supplied @var{function}s. \
If @var{exclude} (a cell array of strings) is given, exclude all functions whose filepaths start with one of the filepath prefixes in @var{exclude}. \
\n\n\
The cell array @var{extras} returns any additional data files required by the functions. \
It is determined by calling any dependent function named '__depends_extra_files__()', which should return file names as multiple string arguments. \
\n\n\
@end deftypefn";

#if OCTAVE_VERSION_HEX >= 0x040400
DEFMETHOD_DLD( depends, interp, args, nargout, depends_usage ) {
#else
DEFUN_DLD( depends, args, nargout, depends_usage ) {
#endif

  // Prevent octave from crashing ...
#if OCTAVE_VERSION_HEX < 0x040400
  octave_exit = ::_Exit;
#endif

  // Check input and output
  if (args.length() == 0 || nargout != 2) {
    print_usage();
    return octave_value();
  }

  // If given, get cell list of excluded prefixes
  Cell exclude;
  octave_idx_type i = 0;
  if (args(0).is_cell()) {
    exclude = args(0).cell_value();
    for (octave_idx_type j = 0; j < exclude.numel(); ++j) {
      if (!exclude(j).is_string()) {
        error("argument #1 is not a cell array of strings");
        return octave_value();
      }
    }
    ++i;
  }

  // Create dependency walker class
#if OCTAVE_VERSION_HEX >= 0x040400
  dependency_walker dep_walk(interp, exclude);
#else
  dependency_walker dep_walk(exclude);
#endif

  // Iterate over input arguments
  for (; i < args.length(); ++i) {

    // Check argument
    if (!args(i).is_string()) {
      error("argument #%i is not a string", i+1);
      return octave_value();
    }

    // Walk over function
    dep_walk.walk_function(args(i).string_value());

  }

  // Create cell array of extra files
  Cell extra_files(1, dep_walk.extra_files.size());
  {
    std::set<std::string>::iterator i = dep_walk.extra_files.begin();
    for (octave_idx_type j = 0; j < extra_files.numel(); ++j, ++i) {
      extra_files.elem(j) = octave_value(*i);
    }
  }

  // Return output
  octave_value_list argout;
  argout.append(octave_value(dep_walk.functions));
  argout.append(octave_value(extra_files));
  return argout;

}

/*

%!test
%!  octprefixes = cellfun("octave_config_info", {"fcnfiledir", "octfiledir"}, "UniformOutput", false);
%!  [deps,extras] = depends(octprefixes, "parseOptions");

*/
