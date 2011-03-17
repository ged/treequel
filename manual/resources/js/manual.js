
// Auto generate a table of contents if a #auto-toc div exists.
//
function generate_toc() {

	$('#auto-toc').append('<h2>Contents</h2><ul></ul>');

	$('section#content h3').each( function() {
		var header = $(this);
		var html = header.html().replace( /^\s*|\s*$/g, '' );
		var newid = html.toLowerCase().replace( /\W+/g, '-' );
		header.prepend( '<a name="' + newid + '" />' );

		$('#auto-toc ul').append( '<li><a href="#' + newid + '">' + html + "</a></li>" );
	});
}


function highlight_examples() {
	SyntaxHighlighter.defaults['ruler'] = false;
	SyntaxHighlighter.defaults['toolbar'] = false;
	SyntaxHighlighter.config.clipboardSwf = null;
	SyntaxHighlighter.all();
}

$(document).ready(function() {
	generate_toc();
	highlight_examples();
});

