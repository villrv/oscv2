from django import forms

class SdbSearchForm(forms.Form):
    changed        = forms.BooleanField(widget = forms.HiddenInput(), initial=True, required=True)
    page           = forms.CharField(widget = forms.HiddenInput(), initial="1", required=True)
    name           = forms.CharField(label='Name', max_length=40, required=False)
    aliases        = forms.CharField(label='Aliases', max_length=40, required=False)
    types          = forms.CharField(label='Types', max_length=40, required=False)
    host           = forms.CharField(label='Host', max_length=40, required=False)
    hostra_degrees = forms.FloatField(label='HostRA', required=False)



