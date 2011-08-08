test:
	node_modules/.bin/nodeunit test/*.tests.js

test_ci:
	rm -rf results && mkdir results && node_modules/.bin/nodeunit --reporter junit --output results test/*.tests.js

checkamd:
	cat lib/check.js | sed 's/var check = exports;/define(function() {\nvar check = {};/' > check-`cat VERSION`.js && echo -e "\n\nreturn check;\n\n});" >> check-`cat VERSION`.js

clean:
	rm -rf docs

docs:
	mkdir docs && dox -p --title "Samurai API documentation" -i GETTING_STARTED.mkd lib/config.js lib/samurai.js lib/transaction.js support/ashigaru.js lib/check.js lib/xmlutils.js lib/authpost.js lib/ducttape.js lib/messages.js lib/error.js > docs/samurai.html

.PHONY: test
