-- these two are combined often enough
return function(cl)
	return require 'glapp.orbit'(require 'glapp.view'.apply(cl))
end
