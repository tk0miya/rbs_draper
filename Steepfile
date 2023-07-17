# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature "sig", "lib/rbs_draper/sig"

  check "lib"

  configure_code_diagnostics(D::Ruby.lenient)
end
