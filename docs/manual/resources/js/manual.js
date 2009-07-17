

// Auto generate a table of contents if a #auto-toc div exists.
//
function generate_toc() {
	
	$('#auto-toc').append('<ul></ul>');
		
	$('h2').each( function() {
		var header = $(this);
		var html = header.html().replace( /^\s*|\s*$/g, '' );
		var newid = html.toLowerCase().replace( /\W+/g, '-' );
		header.prepend( '<a name="' + newid + '" />' );

		console.debug( "Making a link for %s: %o", newid, html );
		$('#auto-toc ul').append( '<li><a href="#' + newid + '">' + html + "</a></li>" );
	});
}


function highlight_examples() {
	SyntaxHighlighter.config.clipboardSwf = 'swf/clipboard.swf';
	SyntaxHighlighter.all();
}

$(document).ready(function() {
	generate_toc();
	highlight_examples();
});


