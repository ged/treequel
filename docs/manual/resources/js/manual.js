
// Auto generate a table of contents if a #auto-toc div exists.
//
function generate_toc() {
	if ( $('#auto-toc').length > 0 ) {
		var toc = $('#auto-toc').wrapInner('<ul></ul>');
		$('h2').each( function() { append_header_to_toc(toc, this); });
	}
};

function append_header_to_toc( toc, item ) {
	var header = $(item);
	var html = header.html().replace( /^\s*|\s*$/g, '' );
	var newid = html.toLowerCase().replace( /\W+/g, '-' );
	header.prepend( '<a name="' + newid + '" />' );
	
	toc.append( '<li><a href="#' + newid + '">' + html + "</a></li>" );
};


$(document).ready(function() {
	generate_toc();
});


