from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader
from sdbapp.models import SdbEntry
from django.views import generic
from django.views.decorators.http import require_http_methods
from django.core.paginator import Paginator
from .forms import SdbSearchForm
import pickle
import codecs
import logging

@require_http_methods(["GET", "POST"])
def index(request):

    ## Handle initial get request. Any other valid access whether
    ## pagination or a form request should be a post.
    if request.method == 'GET':
        form = SdbSearchForm()
        context = {'form': form, 'show_results': False}
        return render(request, 'sdbapp/index.html', context)
        
    idata = request.POST
    odata = request.POST.copy()
    iform = SdbSearchForm(idata)

#    if iform.is_valid():
#        x = 0
    valid = iform.is_valid();
    ##
    ## Handle a POST request with new data.
    ##
    logging.info('submit: %s' % idata['submit'])
    if idata['submit'] == "submitChange":
        objects = SdbEntry.objects.filter(name__istartswith='SN').order_by('id')
        p = Paginator(objects, 25)
        page_number = 1
        request.session['paginator'] = codecs.encode(pickle.dumps(p), "base64").decode()
    else:
        p = pickle.loads(codecs.decode(request.session['paginator'].encode(), "base64"))
        page_number = int(idata.get('page'))
        logging.info('input page_number: %d' % page_number)
        if idata['submit'] == 'prev':
            page_number = page_number - 1
        if idata['submit'] == 'next':
            page_number = page_number + 1

    logging.info('page_number: %d' % page_number)
    logging.info('num_pages: %d' % p.num_pages)

#    try:
    page_obj = p.get_page(page_number)
#    except PageNotAnInteger:
#      page_obj = p.page(1)
#    except EmptyPage:
#      page_obj = p.page(p.num_pages)

    odata['page'] = '%d' % page_number
    oform = SdbSearchForm(odata)
    logging.info('page_obj.number: %d' % page_obj.number)
    context = { 'page_obj' : page_obj, 'form': oform, 'show_results': True }
    return render(request, 'sdbapp/index.html', context)
