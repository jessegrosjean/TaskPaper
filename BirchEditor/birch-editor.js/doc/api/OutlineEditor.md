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
  <h1>OutlineEditor</h1>
  <p>Maps an <a class='reference' href='Outline.html'>
  <code>Outline</code>
</a> into an editable text buffer.</p>
<p>The outline editor maintains the hoisted item, folded items, filter path,
and selected items. It uses this state to determine which items are
displayed and selected in the text buffer. </p>
  
<h2>Finding Outline Editors</h2>
<dl>
  <dt class='method-def' id='static-getOutlineEditors'>
  <code class='signature'>.getOutlineEditors()</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Retrieves all open <a class='reference' href='OutlineEditor.html'>
  <code>OutlineEditor</code>
</a>s.</p>
  <table class='m-t return-value table table-condensed'>
  <thead>
    <tr>
      <th>Return Values</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Returns an <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'>
  <code>Array</code>
</a> of <a class='reference' href='OutlineEditor.html'>
  <code>OutlineEditor</code>
</a>s.
</td></tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='static-getOutlineEditorsForOutline'>
  <code class='signature'>.getOutlineEditorsForOutline(outline)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Return <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'>
  <code>Array</code>
</a> of all <a class='reference' href='OutlineEditor.html'>
  <code>OutlineEditor</code>
</a>s associated with the given
<a class='reference' href='Outline.html'>
  <code>Outline</code>
</a>.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>outline</code></th>
  <td>Edited <a class='reference' href='Outline.html'>
  <code>Outline</code>
</a>.</td>
</tr>
  </tbody>
</table>
</dd>
</dl>
<h2>Outline</h2>
<dl>
  <dt class='property-def' id='instance-outline'>
  <code class='signature'>::outline</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p><a class='reference' href='Outline.html'>
  <code>Outline</code>
</a> that is edited. </p>
</dd>
</dl>
<h2>State</h2>
<dl>
  <dt class='property-def' id='instance-hoistedItem'>
  <code class='signature'>::hoistedItem</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Root of all items displayed in the text buffer. </p>
</dd>
<dt class='property-def' id='instance-focusedItem'>
  <code class='signature'>::focusedItem</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Focused item in the text buffer. Similar to <a class='reference' href='#instance-hoistedItem'>
  <code>::hoistedItem</code>
</a>, but
the hoisted item is never displayed in the text buffer, while
<a class='reference' href='#instance-focusedItem'>
  <code>::focusedItem</code>
</a> is displayed (and temporarily expanded) to show any
children. </p>
</dd>
<dt class='property-def' id='instance-itemPathFilter'>
  <code class='signature'>::itemPathFilter</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Item path formatted <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String'>
  <code>String</code>
</a>. When set only matching items display in the text buffer. </p>
</dd>
</dl>
<h2>Folding Items</h2>
<dl>
  <dt class='method-def' id='instance-fold'>
  <code class='signature'>::fold()</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Toggle folding status of current selection. </p>
</dd>
<dt class='method-def' id='instance-isExpanded'>
  <code class='signature'>::isExpanded(item)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Return true of the given item is expanded.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>item</code></th>
  <td><a class='reference' href='Item.html'>
  <code>Item</code>
</a> to check.</td>
</tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-isFiltered'>
  <code class='signature'>::isFiltered(item)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Return true of the given item has some of its children visible and
others hidden.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>item</code></th>
  <td><a class='reference' href='Item.html'>
  <code>Item</code>
</a> to check.</td>
</tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-isCollapsed'>
  <code class='signature'>::isCollapsed(item)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Return true of the given item is collapsed.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>item</code></th>
  <td><a class='reference' href='Item.html'>
  <code>Item</code>
</a> to check.</td>
</tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-setExpanded'>
  <code class='signature'>::setExpanded(items)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Expand the given item(s).</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>items</code></th>
  <td><a class='reference' href='Item.html'>
  <code>Item</code>
</a> or <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'>
  <code>Array</code>
</a> of items to expand.</td>
</tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-setCollapsed'>
  <code class='signature'>::setCollapsed(items)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Collapse the given item(s).</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>items</code></th>
  <td><a class='reference' href='Item.html'>
  <code>Item</code>
</a> or <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'>
  <code>Array</code>
</a> of items to collapse.</td>
</tr>
  </tbody>
</table>
</dd>
</dl>
<h2>Displayed Items</h2>
<dl>
  <dt class='property-def' id='instance-displayedItems'>
  <code class='signature'>::displayedItems</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'>
  <code>Array</code>
</a> of visible <a class='reference' href='Item.html'>
  <code>Item</code>
</a>s in editor (readonly). </p>
</dd>
<dt class='property-def' id='instance-firstDisplayedItem'>
  <code class='signature'>::firstDisplayedItem</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>First displayed <a class='reference' href='Item.html'>
  <code>Item</code>
</a> in editor (readonly). </p>
</dd>
<dt class='property-def' id='instance-lastDisplayedItem'>
  <code class='signature'>::lastDisplayedItem</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Last displayed <a class='reference' href='Item.html'>
  <code>Item</code>
</a> in editor (readonly). </p>
</dd>
  <dt class='method-def' id='instance-isDisplayed'>
  <code class='signature'>::isDisplayed(item)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Determine if an <a class='reference' href='Item.html'>
  <code>Item</code>
</a> is displayed in the editor’s text buffer. A
displayed item isn’t neccessarily visible because it might be scrolled off
screen. Displayed means that its body text is present and editable in the
buffer.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>item</code></th>
  <td><a class='reference' href='Item.html'>
  <code>Item</code>
</a> to test.</td>
</tr>
  </tbody>
</table>
  <table class='m-t return-value table table-condensed'>
  <thead>
    <tr>
      <th>Return Values</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Returns <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean'>
  <code>Boolean</code>
</a> indicating if item is displayed.
</td></tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-forceDisplayed'>
  <code class='signature'>::forceDisplayed(item, showAncestors<sup>?</sup>)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Force the given <a class='reference' href='Item.html'>
  <code>Item</code>
</a> to display in the editor’s text buffer,
expanding ancestors, removing filters, and unhoisting items as needed.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>item</code></th>
  <td><a class='reference' href='Item.html'>
  <code>Item</code>
</a> to make displayed.</td>
</tr>
<tr>
  <th><code>showAncestors<sup>?</sup></code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean'>
  <code>Boolean</code>
</a> defaults to false.</td>
</tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-forceHidden'>
  <code class='signature'>::forceHidden(item, hideDescendants<sup>?</sup>)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Remove the given <a class='reference' href='Item.html'>
  <code>Item</code>
</a>(s) from display in the editor’s text
buffer, leaving all other items in place.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>item</code></th>
  <td><a class='reference' href='Item.html'>
  <code>Item</code>
</a>(s) to hide.</td>
</tr>
<tr>
  <th><code>hideDescendants<sup>?</sup></code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean'>
  <code>Boolean</code>
</a> defaults to false.</td>
</tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-getNextDisplayedItem'>
  <code class='signature'>::getNextDisplayedItem(item)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>item</code></th>
  <td><a class='reference' href='Item.html'>
  <code>Item</code>
</a></td>
</tr>
  </tbody>
</table>
  <table class='m-t return-value table table-condensed'>
  <thead>
    <tr>
      <th>Return Values</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Returns next displayed <a class='reference' href='Item.html'>
  <code>Item</code>
</a> relative to given item.
</td></tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-getPreviousDisplayedItem'>
  <code class='signature'>::getPreviousDisplayedItem(item)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>item</code></th>
  <td><a class='reference' href='Item.html'>
  <code>Item</code>
</a></td>
</tr>
  </tbody>
</table>
  <table class='m-t return-value table table-condensed'>
  <thead>
    <tr>
      <th>Return Values</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Returns previous displayed <a class='reference' href='Item.html'>
  <code>Item</code>
</a> relative to given item.
</td></tr>
  </tbody>
</table>
</dd>
</dl>
<h2>Text Buffer</h2>
<dl>
  <dt class='property-def' id='instance-textLength'>
  <code class='signature'>::textLength</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only text buffer <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> length. </p>
</dd>
  <dt class='method-def' id='instance-getItemOffsetForLocation'>
  <code class='signature'>::getItemOffsetForLocation(location)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Translate from a text buffer location to an <a class='reference' href='Item.html'>
  <code>Item</code>
</a> offset.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>location</code></th>
  <td>Text buffer character <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> location.</td>
</tr>
  </tbody>
</table>
  <table class='m-t return-value table table-condensed'>
  <thead>
    <tr>
      <th>Return Values</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Returns <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object'>
  <code>Object</code>
</a> with <code>item</code> and <code>offset</code> properties.
</td></tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-getLocationForItemOffset'>
  <code class='signature'>::getLocationForItemOffset(item, offset)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Translate from item offset to the nearest valid text buffer
location.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>item</code></th>
  <td><a class='reference' href='Item.html'>
  <code>Item</code>
</a> to lookup.</td>
</tr>
<tr>
  <th><code>offset</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> offset into the items text.</td>
</tr>
  </tbody>
</table>
  <table class='m-t return-value table table-condensed'>
  <thead>
    <tr>
      <th>Return Values</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Returns text buffer character offset <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a>.
</td></tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-getTextInRange'>
  <code class='signature'>::getTextInRange(location, length)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Get text in the given range.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>location</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character location.</td>
</tr>
<tr>
  <th><code>length</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character range length.</td>
</tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-replaceRangeWithString'>
  <code class='signature'>::replaceRangeWithString(location, length, string)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Replace the given range with a string.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>location</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character location.</td>
</tr>
<tr>
  <th><code>length</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character range length.</td>
</tr>
<tr>
  <th><code>string</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String'>
  <code>String</code>
</a> to insert.</td>
</tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-replaceRangeWithItems'>
  <code class='signature'>::replaceRangeWithItems(location, length, items)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Replace the given range with a items.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>location</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character location.</td>
</tr>
<tr>
  <th><code>length</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character range length.</td>
</tr>
<tr>
  <th><code>items</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'>
  <code>Array</code>
</a> of <a class='reference' href='Item.html'>
  <code>Item</code>
</a>s to insert.</td>
</tr>
  </tbody>
</table>
</dd>
</dl>
<h2>Selection</h2>
<dl>
  <dt class='property-def' id='instance-selection'>
  <code class='signature'>::selection</code>
</dt>
<dd class='property-def m-t-md m-b-md'>
  <p>Read-only <a class='reference' href='Selection.html'>
  <code>Selection</code>
</a> snapshot. </p>
</dd>
  <dt class='method-def' id='instance-moveSelectionToRange'>
  <code class='signature'>::moveSelectionToRange(headLocation, anchorLocation<sup>?</sup>)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Set selection by character locations in text buffer.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>headLocation</code></th>
  <td>Selection focus character <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> location.</td>
</tr>
<tr>
  <th><code>anchorLocation<sup>?</sup></code></th>
  <td>Selection anchor character <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> location.</td>
</tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-moveSelectionToItems'>
  <code class='signature'>::moveSelectionToItems(headItem, headOffset<sup>?</sup>, anchorItem<sup>?</sup>, anchorOffset<sup>?</sup>)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Set selection by <a class='reference' href='Item.html'>
  <code>Item</code>
</a>.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>headItem</code></th>
  <td>Selection head <a class='reference' href='Item.html'>
  <code>Item</code>
</a></td>
</tr>
<tr>
  <th><code>headOffset<sup>?</sup></code></th>
  <td>Selection head offset index. Or <code>undefined</code>  when selecting at item level.</td>
</tr>
<tr>
  <th><code>anchorItem<sup>?</sup></code></th>
  <td>Selection anchor <a class='reference' href='Item.html'>
  <code>Item</code>
</a></td>
</tr>
<tr>
  <th><code>anchorOffset<sup>?</sup></code></th>
  <td>Selection anchor offset index. Or <code>undefined</code>  when selecting at item level.</td>
</tr>
  </tbody>
</table>
</dd>
</dl>
<h2>Scrolling</h2>
<dl>
  <dt class='method-def' id='instance-scrollBy'>
  <code class='signature'>::scrollBy(xDelta, yDelta)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Adjust <a class='reference' href='#instance-scrollPoint'>
  <code>::scrollPoint</code>
</a> by the given delta.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>xDelta</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> scroll point x delta.</td>
</tr>
<tr>
  <th><code>yDelta</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> scroll point y delta.</td>
</tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-scrollRangeToVisible'>
  <code class='signature'>::scrollRangeToVisible(location, length)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Scroll the given range to visible in the text buffer.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>location</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character location.</td>
</tr>
<tr>
  <th><code>length</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character range length.</td>
</tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-getRectForRange'>
  <code class='signature'>::getRectForRange(location, length)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Get rectangle for the given character range.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>location</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character location.</td>
</tr>
<tr>
  <th><code>length</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character range length.</td>
</tr>
  </tbody>
</table>
  <table class='m-t return-value table table-condensed'>
  <thead>
    <tr>
      <th>Return Values</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Returns <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object'>
  <code>Object</code>
</a> with <code>x</code>, <code>y</code>, <code>width</code>, and <code>height</code> keys.
</td></tr>
  </tbody>
</table>
</dd>
<dt class='method-def' id='instance-getCharacterIndexForPoint'>
  <code class='signature'>::getCharacterIndexForPoint(x, y)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Get character index for the given point.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>x</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> x position.</td>
</tr>
<tr>
  <th><code>y</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> y position.</td>
</tr>
  </tbody>
</table>
  <table class='m-t return-value table table-condensed'>
  <thead>
    <tr>
      <th>Return Values</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Returns <a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character index.
</td></tr>
  </tbody>
</table>
</dd>
</dl>
<h2>Item Serialization</h2>
<dl>
  <dt class='method-def' id='instance-serializeRange'>
  <code class='signature'>::serializeRange(location, length, options)</code>
</dt>
<dd class='method-def m-t-md m-b-md'>
  <p>Get item serialization from the given range.</p>
  <table class='parameter table table-condensed'>
  <col style='width:25%'>
  <col style='width:75%'>
  <thead>
    <tr>
      <th>Argument</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
  <th><code>location</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character location.</td>
</tr>
<tr>
  <th><code>length</code></th>
  <td><a class='reference' href='https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'>
  <code>Number</code>
</a> character range length.</td>
</tr>
<tr>
  <th><code>options</code></th>
  <td>Serialization options as defined in <a class='reference' href='ItemSerializer.html'>
  <code>ItemSerializer</code>
</a>.</td>
</tr>
  </tbody>
</table>
</dd>
</dl>
</div>