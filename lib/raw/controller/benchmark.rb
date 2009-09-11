require "benchmark"

module Raw
  
# This helper adds benchmarking support in your Controllers.
# Useful for fine tuning and optimizing your actions.

module BenchmarkHelper

  # Log real time spent on a task. 
  # 
  # === Example
  # 
  # benchmark "Doing an operation" { operation }
  
  def benchmark(message = "Benchmarking")
    real = Benchmark.realtime { yield }
    info "#{message}: time = #{'%.5f' % real} ms."
  end

end

end
