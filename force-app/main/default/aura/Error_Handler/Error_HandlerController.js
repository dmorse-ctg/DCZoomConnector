({
	closeToast: function(component, event, helper) {
		component.set('v.errorResult.message', '');
	},
    errorChange: function(component, event, helper){
        if(!$A.util.isEmpty(component.get('v.errorResult.message'))){
            setTimeout(function(){
                window.scroll({top: 0, left: 0, behavior: 'smooth' });
            }, 1000);
        }
    }
})