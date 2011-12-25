{print}       = require 'sys'
{spawn, exec} = require 'child_process'

build = (watch, callback) ->
  if typeof watch is 'function'
    callback = watch
    watch = false
  options = ['-c', '-o', 'lib', 'src']
  options.unshift '-w' if watch

  coffee = spawn 'coffee', options
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()
  coffee.on 'exit', (status) -> callback?() if status is 0

task 'build', 'Compile Samurai source files', ->
  build()

task 'watch', 'Recompile CoffeeScript source files when modified', ->
  build true

task 'test', 'Run mocha specs', ->
  files = [ 'helpers_spec.coffee'
  	       , 'xml_parser_spec.coffee'
  	       , 'message_spec.coffee'
  	       , 'payment_method_spec.coffee'
  	       , 'processor_spec.coffee'
  	       , 'transaction_spec.coffee'
  	       ]  
  for file in files
    exec "node_modules/mocha/bin/mocha -r should -R spec --slow 5000 --timeout 20000 test/lib/#{file}",
      (err, stdout, stderr) ->
        print stdout if stdout?
        print stderr if stderr?

task 'test-ci', 'Run mocha specs in CI', ->
	exec "node_modules/mocha/bin/mocha -R XUnit -r should --slow 5000 --timeout 20000 test/lib/* >& results.xml",
		(err, stdout, stderr) ->
			print stdout if stdout?
			print stderr if stderr?
