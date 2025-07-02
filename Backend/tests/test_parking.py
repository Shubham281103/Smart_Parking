import json

def test_create_parking_lot(client, auth_headers):
    """
    GIVEN a Flask application and authenticated user
    WHEN a POST request is sent to '/parking/lots'
    THEN check that a '201' status code is returned and a new parking lot is created.
    """
    response = client.post('/parking/lots',
                           headers=auth_headers,
                           data=json.dumps(dict(
                               name='My Test Lot',
                               address='123 Pytest Ave',
                               city='Testville',
                               state='TS',
                               zip_code='12345',
                               country='TC',
                               phone_number='555-0123'
                           )),
                           content_type='application/json')
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data['name'] == 'My Test Lot'
    assert data['address'] == '123 Pytest Ave'

def test_get_parking_lots(client, auth_headers):
    """
    GIVEN a Flask application and an existing parking lot
    WHEN a GET request is sent to '/parking/lots'
    THEN check that a '200' status code is returned and the list contains the parking lot.
    """
    response = client.get('/parking/lots', headers=auth_headers)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert isinstance(data, list)
    assert len(data) > 0
    assert data[0]['name'] == 'My Test Lot'

def test_create_floor(client, auth_headers):
    """
    GIVEN a Flask application and an existing parking lot
    WHEN a POST request is sent to '/parking/lots/1/floors'
    THEN check that a '201' status code is returned and a new floor is created.
    """
    response = client.post('/parking/lots/1/floors',
                           headers=auth_headers,
                           data=json.dumps(dict(name='Floor 1')),
                           content_type='application/json')
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data['name'] == 'Floor 1'

def test_create_row(client, auth_headers):
    """
    GIVEN a Flask application and an existing floor
    WHEN a POST request is sent to '/parking/floors/1/rows'
    THEN check that a '201' status code is returned and a new row is created.
    """
    response = client.post('/parking/floors/1/rows',
                           headers=auth_headers,
                           data=json.dumps(dict(name='Row A')),
                           content_type='application/json')
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data['name'] == 'Row A'

def test_create_slot(client, auth_headers):
    """
    GIVEN a Flask application and an existing row
    WHEN a POST request is sent to '/parking/rows/1/slots'
    THEN check that a '201' status code is returned and a new slot is created.
    """
    response = client.post('/parking/rows/1/slots',
                           headers=auth_headers,
                           data=json.dumps(dict(name='A1')),
                           content_type='application/json')
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data['name'] == 'A1'
    assert data['status'] == 0 # Default status 