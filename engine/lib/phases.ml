module Direct_and_mut = Phase_direct_and_mut.Make
module And_mut_defsite = Phase_and_mut_defsite.Make
module Drop_references = Phase_drop_references.Make
module Drop_blocks = Phase_drop_blocks.Make
module Reconstruct_for_loops = Phase_reconstruct_for_loops.Make
module Reconstruct_question_marks = Phase_reconstruct_question_marks.Make
module Trivialize_assign_lhs = Phase_trivialize_assign_lhs.Make
module Cf_into_monads = Phase_cf_into_monads.Make
module Functionalize_loops = Phase_functionalize_loops.Make
module Reject = Phase_reject
module Local_mutation = Phase_local_mutation.Make
