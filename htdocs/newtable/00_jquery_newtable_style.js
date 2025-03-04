/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2021] EMBL-European Bioinformatics Institute
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

(function($) {
  $.fn.new_table_style = function(config,data) {
    return {
      generate: function() {
        var out = 'Layout <div class="new_table_pagesize">' +
               '<select size="1">';
        $.each(data.styles,function(i,el) {
          var key = el[0];
          var text = el[1];
          if(el===0) { text = "All"; }
          out += '<option value="'+key+'">'+text+'</option>';
        });
        out += '</select></div>';
        return out;
      },
      go: function($table,$el) {
        var view = $table.data('view');
        if(view.hasOwnProperty('format')) {
          $('option',$el).removeAttr('selected');
          $('option[value="'+view.format+'"]',$el).attr('selected',true); 
        }
        $('select',$el).change(function() {
          var $option = $('option:selected',$(this));
          var view = $table.data('view');
          view.format = $option.val();
          $table.data('view',view);
          $table.trigger('view-updated');
        });
      }
    };
  }; 

})(jQuery);
