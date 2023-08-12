<div class='class-def'>
  <script type="text/javascript" src="https://code.jquery.com/jquery-2.2.0.min.js"></script>
  <script>
    $( document ).ready(function() {
      $('.class-def dd').hide();
      $('.class-def dt').click(function(){
        $(this).next('dd').slideToggle();
      });
    });
  </script>
  <h1>Selection</h1>
  <p>Read-only selection snapshot from <a class='reference' href='OutlineEditor.html#instance-selection'>
  <code>OutlineEditor::selection</code>
</a>.</p>
<p>This selection can not be changed and will not update when the outline or
editor selection changes. Use <a class='reference' href='OutlineEditor.html#instance-moveSelectionToItems'>
  <code>OutlineEditor::moveSelectionToItems</code>
</a> or
<a class='reference' href='OutlineEditor.html#instance-moveSelectionToRange'>
  <code>OutlineEditor::moveSelectionToRange</code>
</a> to change the editor’s selection.</p>
<p>The selection character offsets are always valid, but in some cases the
selection endpoint <a class='reference' href='Item.html'>
  <code>Item</code>
</a>s maybe be null. For instance if the
<a class='reference' href='OutlineEditor.html'>
  <code>OutlineEditor</code>
</a> has hoisted an item that has no children then the character
selection will be <code>0,0</code>, but <a class='reference' href='#instance-startItem'>
  <code>::startItem</code>
</a> and <a class='reference' href='#instance-endItem'>
  <code>::endItem</code>
</a> will be <code>null</code>.</p>
<p>The <a class='reference' href='#instance-endItem'>
  <code>::endItem</code>
</a> end point isn’t always the last item in <a class='reference' href='#instance-selectedItems'>
  <code>::selectedItems</code>
</a>.
For example if <a class='reference' href='#instance-endItem'>
  <code>::endItem</code>
</a> doesn’t equal <a class='reference' href='#instance-startItem'>
  <code>::startItem</code>
</a> and <a class='reference' href='#instance-endOffset'>
  <code>::endOffset</code>
</a> is
0 then <a class='reference' href='#instance-endItem'>
  <code>::endItem</code>
</a> isn’t included in the selected items because it doesn’t
overlap the selection, it’s just an endpoint anchor, not a selcted item. </p>
  
<h2>Selection</h2>
<dl>
  <dt class='property-def' id='instance-isCollapsed'>
  <code class='signature'>::isCollapsed</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only true if selection start equals end. </p>
</dd>
<dt class='property-def' id='instance-isFullySelectingItems'>
  <code class='signature'>::isFullySelectingItems</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only true if selection starts at item start boundary and ends
at item end boundary. </p>
</dd>
</dl>
<h2>Characters</h2>
<dl>
  <dt class='property-def' id='instance-start'>
  <code class='signature'>::start</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only selection start character offset. </p>
</dd>
<dt class='property-def' id='instance-end'>
  <code class='signature'>::end</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only selection end character offset. </p>
</dd>
<dt class='property-def' id='instance-location'>
  <code class='signature'>::location</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only selection character location offset. </p>
</dd>
<dt class='property-def' id='instance-length'>
  <code class='signature'>::length</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only selection character length. </p>
</dd>
</dl>
<h2>Items</h2>
<dl>
  <dt class='property-def' id='instance-startItem'>
  <code class='signature'>::startItem</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only selection start <a class='reference' href='Item.html'>
  <code>Item</code>
</a> (or null) in outline order. </p>
</dd>
<dt class='property-def' id='instance-startOffset'>
  <code class='signature'>::startOffset</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only text offset in the <a class='reference' href='#instance-startItem'>
  <code>::startItem</code>
</a> where selection starts. </p>
</dd>
<dt class='property-def' id='instance-endItem'>
  <code class='signature'>::endItem</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only selection endpoint <a class='reference' href='Item.html'>
  <code>Item</code>
</a> (or null) in outline order. </p>
</dd>
<dt class='property-def' id='instance-endOffset'>
  <code class='signature'>::endOffset</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only text offset endpoint in <a class='reference' href='#instance-endItem'>
  <code>::endItem</code>
</a> or undefined. </p>
</dd>
<dt class='property-def' id='instance-selectedItems'>
  <code class='signature'>::selectedItems</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'>
  <code>Array</code>
</a> of <a class='reference' href='Item.html'>
  <code>Item</code>
</a>s intersecting the selection. Does not
include <a class='reference' href='#instance-endItem'>
  <code>::endItem</code>
</a> if <a class='reference' href='#instance-endItem'>
  <code>::endItem</code>
</a> doesn’t equal <a class='reference' href='#instance-startItem'>
  <code>::startItem</code>
</a> and
<a class='reference' href='#instance-endOffset'>
  <code>::endOffset</code>
</a> is 0. Does include all overlapped outline items, including
folded and hidden ones, between the start and end items. </p>
</dd>
<dt class='property-def' id='instance-displayedSelectedItems'>
  <code class='signature'>::displayedSelectedItems</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'>
  <code>Array</code>
</a> of displayed <a class='reference' href='Item.html'>
  <code>Item</code>
</a>s intersecting the selection.
Does not include <a class='reference' href='#instance-endItem'>
  <code>::endItem</code>
</a> if <a class='reference' href='#instance-endItem'>
  <code>::endItem</code>
</a> doesn’t equal <a class='reference' href='#instance-startItem'>
  <code>::startItem</code>
</a>
and <a class='reference' href='#instance-endOffset'>
  <code>::endOffset</code>
</a> is 0. Does not include items that the selection overlaps
but that are hidden in the editor. </p>
</dd>
<dt class='property-def' id='instance-displayedAncestorSelectedItems'>
  <code class='signature'>::displayedAncestorSelectedItems</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'>
  <code>Array</code>
</a> of displayed <a class='reference' href='Item.html'>
  <code>Item</code>
</a>s intersecting the selection.
Does not include <a class='reference' href='#instance-endItem'>
  <code>::endItem</code>
</a> if <a class='reference' href='#instance-endItem'>
  <code>::endItem</code>
</a> doesn’t equal <a class='reference' href='#instance-startItem'>
  <code>::startItem</code>
</a>
and <a class='reference' href='#instance-endOffset'>
  <code>::endOffset</code>
</a> is 0. Does include items that overlap the selection by
that are not visible. </p>
</dd>
<dt class='property-def' id='instance-selectedItemsCommonAncestors'>
  <code class='signature'>::selectedItemsCommonAncestors</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'>
  <code>Array</code>
</a> of the common ancestors of <a class='reference' href='#instance-selectedItems'>
  <code>::selectedItems</code>
</a>. </p>
</dd>
</dl>
</div>