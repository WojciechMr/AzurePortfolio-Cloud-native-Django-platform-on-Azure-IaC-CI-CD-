from django.http import JsonResponse, HttpResponse
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest

def health(request):
    return JsonResponse({"status": "ok"})

def metrics(request):
    data = generate_latest()
    return HttpResponse(data, content_type=CONTENT_TYPE_LATEST)
