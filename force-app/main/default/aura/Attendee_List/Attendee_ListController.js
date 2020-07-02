({
	manageSelection: function(component, event, helper) {
		var selectAll = component.get('v.selectAll');
        var attendees = component.get('v.lstAttendees');
        for(var i = 0; i < attendees.length; i++){
            attendees[i].isSelected = selectAll;
        }
        component.set('v.lstAttendees', attendees);
    },
    manageSingleSelection: function(component, event, helper) {
        var selectAll = true;
        if(!event.getSource().get('v.value'))
            selectAll = false;
        else{
            var attendees = component.get('v.lstAttendees');
            for(var i = 0; i < attendees.length; i++){
                if(!attendees[i].isSelected){
                    selectAll = false;
                    break;
                }
            }
        }
        component.set('v.selectAll', selectAll);
    }
})