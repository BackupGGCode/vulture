# -*- coding: utf-8 -*-
from django.conf.urls.defaults import *
from django.contrib.auth.models import User
from vulture.models import *
from django.contrib import admin
from vulture.views import *

admin.autodiscover()

urlpatterns = patterns('',
  (r'^accounts/login/$',                      'vulture.views.logon'),
  (r'^/?$',                                    'vulture.views.vulture_object_list_adm', dict({'queryset': App.objects.all().order_by('name')}, allow_empty=1)),
  (r'^user/$',                                'vulture.views.vulture_object_list_adm', dict({'queryset': User.objects.all()}, template_name='vulture/user_list.html')),
  (r'^user/(?P<object_id>\d+)/$',             'vulture.views.edit_user'),
  (r'^user/(?P<object_id>\d+)/password/$',    'vulture.views.edit_user_password'),
  (r'^user/new/$',                            'vulture.views.create_user'),
  (r'^user/(?P<object_id>\d+)/del/$',         'vulture.views.vulture_delete_object_adm', dict({'model': User}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='System', name='User', url='/user'), post_delete_redirect='/user/')),
  (r'^app/$',                                 'vulture.views.vulture_object_list_adm', dict({'queryset': App.objects.all().order_by('name')}, allow_empty=1)),
  (r'^app/(?P<object_id>\d+)/$',              'vulture.views.edit_app'),
  (r'^app/new/$',                             'vulture.views.edit_app'),
  (r'^app/(?P<object_id>\d+)/del/$',          'vulture.views.vulture_delete_object_adm', dict({'model': App}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='Web Applications', name='App', url='/app'), post_delete_redirect='/app/')),
  (r'^app/(?P<object_id>\d+)/start/$',        'vulture.views.start_app'),
  (r'^app/(?P<object_id>\d+)/stop/$',         'vulture.views.stop_app'),
  (r'^app/copy/$',                            'vulture.views.copy_app'),
  (r'^sso/$',                                 'vulture.views.vulture_object_list_adm', dict({'queryset': SSO.objects.filter(type = 'sso_forward')}, template_name='vulture/generic_list.html', extra_context = dict(category='Authentication', name='Web SSO', url='/sso'))),
  (r'^sso/(?P<object_id>\d+)/$',              'vulture.views.edit_sso'),
  (r'^sso/new/$',                             'vulture.views.edit_sso'),
  (r'^sso/(?P<object_id>\d+)/del/$',          'vulture.views.vulture_delete_object_adm', dict({'model' : SSO}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='Authentication', name='Web SSO', url='/sso'), post_delete_redirect='/sso/')),
  (r'^intf/$',                                'vulture.views.vulture_object_list_adm', dict({'queryset': Intf.objects.all()}, allow_empty=1)),
  (r'^intf/(?P<object_id>\d+)/$',             'vulture.views.edit_intf'),
  (r'^intf/new/$',                            'vulture.views.edit_intf'),
  (r'^intf/(?P<object_id>\d+)/del/$',         'vulture.views.vulture_delete_object_adm', dict({'model': Intf}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='System', name='Interfaces', url='/intf'), post_delete_redirect='/intf/')),
  (r'^intf/(?P<intf_id>\d+)/start/$',         'vulture.views.start_intf'),
  (r'^intf/(?P<intf_id>\d+)/stop/$',          'vulture.views.stop_intf'),
  (r'^intf/(?P<intf_id>\d+)/reload/$',        'vulture.views.reload_intf'),
  (r'^intf/reloadAll/$',                      'vulture.views.reload_all_intfs'),
  (r'^sql/$',                                 'vulture.views.vulture_object_list_adm', dict({'queryset': SQL.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Authentication', name='SQL', url='/sql', fields=(('driver','Driver'), ('database','Database'))))),
  (r'^(?P<url>sql)/(?P<object_id>\d+)/$',     'vulture.views.edit_auth'),
  (r'^(?P<url>sql)/new/$',                    'vulture.views.edit_auth'),
  (r'^(?P<url>sql)/(?P<object_id>\d+)/del/$', 'vulture.views.remove_auth'),
  (r'^radius/$',                              'vulture.views.vulture_object_list_adm', dict({'queryset': RADIUS.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Authentication', name='RADIUS', url='/radius', fields=(('host','Host'), ('port','Port'))))),
  (r'^(?P<url>radius)/(?P<object_id>\d+)/$',  'vulture.views.edit_auth'),
  (r'^(?P<url>radius)/new/$',                      'vulture.views.edit_auth'),
  (r'^(?P<url>radius)/(?P<object_id>\d+)/del/$',   'vulture.views.remove_auth'),
  (r'^kerberos/$',                                 'vulture.views.vulture_object_list_adm', dict({'queryset': Kerberos.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Authentication', name='Kerberos', url='/kerberos', fields=(('realm','Realm'),)))),
  (r'^(?P<url>kerberos)/(?P<object_id>\d+)/$',     'vulture.views.edit_auth'),
  (r'^(?P<url>kerberos)/new/$',                    'vulture.views.edit_auth'),
  (r'^(?P<url>kerberos)/(?P<object_id>\d+)/del/$', 'vulture.views.remove_auth'),
  (r'^cas/$',                                 'vulture.views.vulture_object_list_adm', dict({'queryset': CAS.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Authentication', name='CAS', url='/cas', fields=(('url_login','URL Login'),('url_validate','URL Validate'))))),
  (r'^(?P<url>cas)/(?P<object_id>\d+)/$',     'vulture.views.edit_auth'),
  (r'^(?P<url>cas)/new/$',                    'vulture.views.edit_auth'),
  (r'^(?P<url>cas)/(?P<object_id>\d+)/del/$', 'vulture.views.remove_auth'),
  (r'^ssl/$',                                 'vulture.views.vulture_object_list_adm', dict({'queryset': SSL.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Authentication', name='SSL', url='/ssl', fields=(('require','Require'),)))),
  (r'^(?P<url>ssl)/(?P<object_id>\d+)/$',     'vulture.views.edit_auth'),
  (r'^(?P<url>ssl)/new/$',                    'vulture.views.edit_auth'),
  (r'^(?P<url>ssl)/(?P<object_id>\d+)/del/$', 'vulture.views.remove_auth'),
  (r'^ntlm/$',                                'vulture.views.vulture_object_list_adm', dict({'queryset': NTLM.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Authentication', name='NTLM', url='/ntlm', fields=(('domain','Domain'), ('primary_dc','Primary DC'), ('secondary_dc','Secondary DC'))))),
  (r'^(?P<url>ntlm)/(?P<object_id>\d+)/$',    'vulture.views.edit_auth'),
  (r'^(?P<url>ntlm)/new/$',                   'vulture.views.edit_auth'),
  (r'^(?P<url>ntlm)/(?P<object_id>\d+)/del/$','vulture.views.remove_auth'),
  (r'^ldap/$',                                'vulture.views.vulture_object_list_adm', dict({'queryset': LDAP.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Authentication', name='LDAP', url='/ldap', fields=(('host','Host'), ('port','Port'))))),
  (r'^(?P<url>ldap)/(?P<object_id>\d+)/$',    'vulture.views.edit_auth'),
  (r'^(?P<url>ldap)/new/$',                   'vulture.views.edit_auth'),
  (r'^(?P<url>ldap)/(?P<object_id>\d+)/del/$','vulture.views.remove_auth'), 
  (r'^acl/$',                                 'vulture.views.vulture_object_list_adm', dict({'queryset': ACL.objects.all()}, allow_empty=1)),
  (r'^acl/(?P<object_id>\d+)/$',              'vulture.views.edit_acl'),
  (r'^acl/new/$',                             'vulture.views.edit_acl'),
  (r'^acl/(?P<object_id>\d+)/del/$',          'vulture.views.vulture_delete_object_adm', dict({'model': ACL}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='Authentication', name='ACL', url='/acl'), post_delete_redirect='/acl/')),
  (r'^/?$',                                   'vulture.views.vulture_object_list_adm', {'queryset': User.objects.all()}),
  (r'^logon/$',                               'vulture.views.logon'),
  (r'^logout/$',                              'logout'),
  (r'^logon/None$',                           'vulture.views.vulture_object_list_adm', dict({'queryset': App.objects.all()}, allow_empty=1)),
  (r'^log/$',                                 'vulture.views.vulture_object_list_adm', dict({'queryset': Log.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='System', name='Log', url='/log', fields=(('level','Level'),)))),
  (r'^log/(?P<object_id>\d+)/$',              'vulture.views.vulture_update_object_adm', dict({'model': Log}, post_save_redirect='/log/')),
  (r'^log/new/$',                             'vulture.views.vulture_create_object_adm', dict({'model': Log}, post_save_redirect='/log/')),
  (r'^log/(?P<object_id>\d+)/del/$',          'vulture.views.vulture_delete_object_adm', dict({'model': Log}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='System', name='Log', url='/log'), post_delete_redirect='/log/')),
  (r'^security/$',                            'vulture.views.vulture_object_list_adm', dict({'queryset': ModSecurity.objects.all()})),
  (r'^security/(?P<object_id>\d+)/$',         'vulture.views.vulture_update_object_adm', dict({'model': ModSecurity}, post_save_redirect='/security')),
  (r'^security/new/$',                        'vulture.views.edit_security'),
  (r'^security/update/$',                     'vulture.views.update_security'),
  (r'^security/(?P<object_id>\d+)/del/$',     'vulture.views.vulture_delete_object_adm', dict({'model': ModSecurity}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='Web Firewall', name='Mod_Security', url='/security'), post_delete_redirect='/security/')),
  
  (r'^plugin/$',                              'vulture.views.vulture_object_list_adm', dict({'queryset': Plugin.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Web Applications', name='Plugin', url='/plugin', noname=True, fields=(('app','App'), ('uri_pattern','URI Pattern'), ('type','Type'), ('options','Options'))))),
  (r'^plugin/(?P<object_id>\d+)/$',           'vulture.views.vulture_update_object_adm', dict({'model': Plugin}, post_save_redirect='/plugin/')),
  (r'^plugin/new/$',                          'vulture.views.vulture_create_object_adm', dict({'model': Plugin}, post_save_redirect='/plugin/')),
  (r'^plugin/(?P<object_id>\d+)/del/$',       'vulture.views.vulture_delete_object_adm', dict({'model': Plugin}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='Web Applications', name='Plugin', url='/plugin'), post_delete_redirect='/plugin/')),
  (r'^appearance/$',                          'vulture.views.vulture_object_list_adm', dict({'queryset': Appearance.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Appearance', name='Appearance', url='/appearance', fields=(('css','CSS'), ('login_tpl','Login template'), ('image','Image'))))),
  (r'^appearance/(?P<object_id>\d+)/$',       'vulture.views.vulture_update_object_adm', dict({'model': Appearance}, post_save_redirect='/appearance/')),
  (r'^appearance/new/$',                      'vulture.views.vulture_create_object_adm', dict({'model': Appearance}, post_save_redirect='/appearance/')),
  (r'^appearance/(?P<object_id>\d+)/del/$',   'vulture.views.vulture_delete_object_adm', dict({'model': Appearance}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='Appearance', name='Appearance', url='/appearance'), post_delete_redirect='/appearance/')),
  (r'^template_css/$',                        'vulture.views.vulture_object_list_adm', dict({'queryset': CSS.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Appearance', name='CSS', url='/template_css'))),
  (r'^template_css/(?P<object_id>\d+)/$',     'vulture.views.vulture_update_object_adm', dict({'model': CSS}, post_save_redirect='/template_css/')),
  (r'^template_css/new/$',                    'vulture.views.vulture_create_object_adm', dict({'model': CSS}, post_save_redirect='/template_css/')),
  (r'^template_css/(?P<object_id>\d+)/del/$', 'vulture.views.vulture_delete_object_adm', dict({'model': CSS}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='Appearance', name='CSS', url='/template_css'), post_delete_redirect='/template_css/')),
  (r'^template/$',                            'vulture.views.vulture_object_list_adm', dict({'queryset': Template.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Appearance', name='Template', url='/template', fields=(('type','Type'),)))),
  (r'^template/(?P<object_id>\d+)/$',         'vulture.views.vulture_update_object_adm', dict({'model': Template}, post_save_redirect='/template/')),
  (r'^template/new/$',                        'vulture.views.vulture_create_object_adm', dict({'model': Template}, post_save_redirect='/template/')),
  (r'^template/(?P<object_id>\d+)/del/$',     'vulture.views.vulture_delete_object_adm', dict({'model': Template}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='Appearance', name='Template', url='/template'), post_delete_redirect='/template/')),
  (r'^image/$',                               'vulture.views.vulture_object_list_adm', dict({'queryset': Image.objects.all()}, template_name='vulture/generic_list.html', extra_context = dict(category='Appearance', name='Image', url='/image'))),
  (r'^image/(?P<object_id>\d+)/$',            'vulture.views.vulture_update_object_adm', dict({'model': Image}, post_save_redirect='/image/')),
  (r'^image/new/$',                           'vulture.views.vulture_create_object_adm', dict({'model': Image}, post_save_redirect='/image/')),
  (r'^image/(?P<object_id>\d+)/del/$',        'vulture.views.vulture_delete_object_adm', dict({'model': Image}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='Appearance', name='Image', url='/image'), post_delete_redirect='/image/')),
  (r'^localization/$',                        'vulture.views.vulture_object_list_adm', dict({'queryset': Localization.objects.all().order_by('country')}, template_name='vulture/generic_list.html', extra_context = dict(category='System', name='Localization', url='/localization',  noname=True, fields=(('country','Country'), ('message','Message'), ('translation','Translation'))))),
  (r'^localization/(?P<object_id>\d+)/$',     'vulture.views.edit_localization'),
  (r'^localization/new/$',                    'vulture.views.edit_localization'),
  (r'^localization/(?P<object_id>\d+)/del/$', 'vulture.views.vulture_delete_object_adm', dict({'model': Localization}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='System', name='Localization', url='/localization'), post_delete_redirect='/localization/')),
  (r'^event/$',                               'vulture.views.view_event'),
  (r'^(?P<type>import|export)/$',             'vulture.views.export_import_config'),
  (r'^plugincontent/$',                              'vulture.views.vulture_object_list_adm', dict({'queryset': Plugincontent.objects.all().order_by('app')}, template_name='vulture/generic_list.html', extra_context = dict(category='Web Applications', name='Plugin Content Rewrite', url='/plugincontent', noname=True, fields=(('app','Application'), ('pattern','Pattern'), ('type','Type'), ('options','Options'), ('options1','Options1'))))),
  (r'^plugincontent/(?P<object_id>\d+)/$',           'vulture.views.vulture_update_object_adm', dict({'model': Plugincontent}, post_save_redirect='/plugincontent/')),
  (r'^plugincontent/new/$',                          'vulture.views.vulture_create_object_adm', dict({'model': Plugincontent}, post_save_redirect='/plugincontent/')),
  (r'^plugincontent/(?P<object_id>\d+)/del/$',       'vulture.views.vulture_delete_object_adm', dict({'model': Plugincontent}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='Web Applications', name='Plugin Content Rewrite', url='/plugincontent'), post_delete_redirect='/plugincontent/')),
  (r'^pluginheader/$',                              'vulture.views.vulture_object_list_adm', dict({'queryset': Pluginheader.objects.all().order_by('app')}, template_name='vulture/generic_list.html', extra_context = dict(category='Web Applications', name='Plugin Header Input', url='/pluginheader', noname=True, fields=(('app','Application'), ('pattern','Pattern'), ('type','Type'), ('options','Options'), ('options1','Options1'))))),
  (r'^pluginheader/(?P<object_id>\d+)/$',           'vulture.views.vulture_update_object_adm', dict({'model': Pluginheader}, post_save_redirect='/pluginheader/')),
  (r'^pluginheader/new/$',                          'vulture.views.vulture_create_object_adm', dict({'model': Pluginheader}, post_save_redirect='/pluginheader/')),
  (r'^pluginheader/(?P<object_id>\d+)/del/$',       'vulture.views.vulture_delete_object_adm', dict({'model': Pluginheader}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='Web Applications', name='Plugin Header Input', url='/pluginheader'), post_delete_redirect='/pluginheader/')),
  (r'^blackip/$',                              'vulture.views.vulture_object_list_adm', dict({'queryset': BlackIP.objects.all().order_by('app')}, template_name='vulture/generic_list.html', extra_context = dict(category='Web Firewall', name='BlackIP', url='/blackip', noname=True, fields=(('app','Application'), ('ip','IP'))))),
  (r'^blackip/(?P<object_id>\d+)/$',           'vulture.views.vulture_update_object_adm', dict({'model': BlackIP}, post_save_redirect='/blackip/')),
  (r'^blackip/new/$',                          'vulture.views.vulture_create_object_adm', dict({'model': BlackIP}, post_save_redirect='/blackip/')),
  (r'^blackip/(?P<object_id>\d+)/del/$',       'vulture.views.vulture_delete_object_adm', dict({'model': BlackIP}, template_name='vulture/generic_confirm_delete.html', extra_context = dict(category='BlackIP', name='BlackIP', url='/blackip'), post_delete_redirect='/blackip/')),
  (r'^img/(.*)$',                             'django.views.static.serve',                  {'document_root': 'img'}),
  (r'^css/(.*)$',                             'django.views.static.serve',                  {'document_root': 'css'}),
  (r'^js/(.*)$',                              'django.views.static.serve',                  {'document_root': 'js'}),
  (r'^xml/(.*)$',                             'django.views.static.serve',                  {'document_root': 'xml'}),
  (r'^vintf/$',                                'vulture.views.vulture_object_list_adm', dict({'queryset': VINTF.objects.all()}, template_name='vulture/vintf_list.html', extra_context = dict(category='System', name='Virtual Interfaces', url='/vintf', fields=(('intf','Interface'),('ip','IP'),('netmask','Netmask'),('broadcast','Broadcast Address'))))),
  (r'^vintf/(?P<object_id>\d+)/$',    'vulture.views.edit_vintf'),
  (r'^vintf/new/$',                   'vulture.views.edit_vintf'),
  (r'^vintf/(?P<object_id>\d+)/del/$','vulture.views.remove_vintf'),
  (r'^vintf/(?P<object_id>\d+)/start/$' , 'vulture.views.start_vintf'),
  (r'^vintf/(?P<object_id>\d+)/stop/$', 'vulture.views.stop_vintf'),
  (r'^vintf/reloadAll/$',                      'vulture.views.reload_all_vintfs'),

   (r'^conf/$',		'vulture.views.vulture_object_list_adm', dict({'queryset':Conf.objects.all().order_by('id')}, template_name='vulture/generic_list.html', extra_context = dict(category='System', name='Globales' , url='/conf', noname=True, fields=(('var','Name'),('value','Value'))))),
  (r'^conf/(?P<object_id>\d+)/$','vulture.views.vulture_update_object_adm',dict({'model':Conf}, post_save_redirect='/conf')),
  (r'^conf/new/$','vulture.views.vulture_create_object_adm' , dict({'model':Conf}, post_save_redirect='/conf')),
  (r'^conf/(?P<object_id>\d+)/del/$','vulture.views.vulture_delete_object_adm' , dict({'model':Conf}, template_name='vulture/generic_confirm_delete.html',extra_context= dict(category='System', name='Globales', url='/conf'), post_delete_redirect='/conf/')),
  (r'^cluster/$',	'vulture.views.manage_cluster'),
)
