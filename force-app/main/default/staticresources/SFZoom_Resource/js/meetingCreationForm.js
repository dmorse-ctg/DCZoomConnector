/**  
The MIT License
Copyright © 2020 DataColada Pty Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
**/

var currentIndex;
function showParticipants(strParticipants, index){
	var row = document.getElementsByClassName('current-row-'+index)[0];
	if(strParticipants != '')
		strParticipants = JSON.parse(strParticipants);
	else strParticipants = {participants : []};
	hideParticipants(currentIndex);
	document.getElementsByClassName('accordian-open-'+index)[0].style.display = 'none';
	document.getElementsByClassName('accordian-close-'+index)[0].style.display = 'inline';
	tableCreate(row, strParticipants.participants);
	currentIndex = index;
}
function tableCreate(row, arrParticipants) {
	var tbody = row.getElementsByTagName('tbody')[0];
	var trs = tbody.getElementsByTagName('tr');
	if(trs.length == 0){
		if(arrParticipants.length > 0){
			for (var i = 0; i < arrParticipants.length; i++) {
				var tr = document.createElement('tr');
				
				var td_id = document.createElement('td');
				td_id.appendChild(document.createTextNode(arrParticipants[i].id))
				tr.appendChild(td_id);
				
				var td_name = document.createElement('td');
				td_name.appendChild(document.createTextNode(arrParticipants[i].name));                        
				tr.appendChild(td_name);
				
				tbody.appendChild(tr);
			}
		}else{
			var tr = document.createElement('tr');                            
			var td_id = document.createElement('td');
			td_id.appendChild(document.createTextNode('No participants available.'))
			tr.appendChild(td_id);
			tbody.appendChild(tr);
		}
	}
	row.style.display = 'table-row';
}
function hideParticipants(index){
	if(index != undefined){
		document.getElementsByClassName('accordian-close-'+index)[0].style.display = 'none';
		document.getElementsByClassName('accordian-open-'+index)[0].style.display = 'inline';
		document.getElementsByClassName('current-row-'+index)[0].style.display = 'none';
	}
}