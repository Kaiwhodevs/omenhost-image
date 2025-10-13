#!/bin/bash
# Setup NOWPayments integration for Fleio

echo "Setting up NOWPayments integration..."

# Create NOWPayments configuration file
cat > /opt/fleio/conf/nowpayments.conf << EOF
# NOWPayments Configuration for Fleio
[nowpayments]
api_key = ${FLEIO_NOWPAYMENTS_API_KEY}
ipn_secret = ${FLEIO_NOWPAYMENTS_IPN_SECRET}
sandbox_mode = ${FLEIO_NOWPAYMENTS_SANDBOX}
supported_crypto = ${FLEIO_NOWPAYMENTS_CRYPTO}

# API endpoints
api_url = https://api.nowpayments.io/v1
ipn_url = https://api.nowpayments.io/v1/ipn

# Payment settings
payment_timeout = 3600
confirmation_blocks = 3
min_payment_amount = 0.001
max_payment_amount = 1000.0

# Supported cryptocurrencies
crypto_currencies = BTC,ETH,LTC,USDT,USDC,BNB,ADA,DOT,DOGE,SHIB
EOF

# Create NOWPayments payment processor
cat > /opt/fleio/payment_processors/nowpayments.py << 'EOF'
"""
NOWPayments payment processor for Fleio
"""

import requests
import hashlib
import hmac
import json
from decimal import Decimal
from django.conf import settings
from fleio.billing.models import Invoice
from fleio.billing.payment_processors.base import PaymentProcessorBase


class NOWPaymentsProcessor(PaymentProcessorBase):
    name = 'nowpayments'
    display_name = 'NOWPayments (Cryptocurrency)'
    
    def __init__(self):
        self.api_key = getattr(settings, 'NOWPAYMENTS_API_KEY', '')
        self.ipn_secret = getattr(settings, 'NOWPAYMENTS_IPN_SECRET', '')
        self.sandbox = getattr(settings, 'NOWPAYMENTS_SANDBOX', False)
        self.api_url = 'https://api.nowpayments.io/v1'
        if self.sandbox:
            self.api_url = 'https://api-sandbox.nowpayments.io/v1'
    
    def create_payment(self, invoice, amount, currency='USD'):
        """Create a NOWPayments payment request"""
        try:
            # Get supported cryptocurrencies
            crypto_currencies = self.get_supported_currencies()
            if not crypto_currencies:
                return None, 'No supported cryptocurrencies available'
            
            # Create payment request
            payment_data = {
                'price_amount': float(amount),
                'price_currency': currency,
                'pay_currency': crypto_currencies[0],  # Use first available crypto
                'order_id': f'fleio_invoice_{invoice.id}',
                'order_description': f'Fleio Invoice #{invoice.id}',
                'ipn_callback_url': f'{settings.SITE_URL}/billing/nowpayments/callback/',
                'case': 'success'
            }
            
            headers = {
                'x-api-key': self.api_key,
                'Content-Type': 'application/json'
            }
            
            response = requests.post(
                f'{self.api_url}/payment',
                json=payment_data,
                headers=headers,
                timeout=30
            )
            
            if response.status_code == 201:
                payment_info = response.json()
                return payment_info, None
            else:
                return None, f'Payment creation failed: {response.text}'
                
        except Exception as e:
            return None, f'Error creating payment: {str(e)}'
    
    def get_supported_currencies(self):
        """Get list of supported cryptocurrencies"""
        try:
            headers = {'x-api-key': self.api_key}
            response = requests.get(
                f'{self.api_url}/currencies',
                headers=headers,
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get('currencies', [])
            return []
        except:
            return ['BTC', 'ETH', 'LTC']  # Fallback currencies
    
    def verify_payment(self, payment_id):
        """Verify payment status"""
        try:
            headers = {'x-api-key': self.api_key}
            response = requests.get(
                f'{self.api_url}/payment/{payment_id}',
                headers=headers,
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            return None
        except:
            return None
    
    def verify_ipn(self, data, signature):
        """Verify IPN signature"""
        try:
            expected_signature = hmac.new(
                self.ipn_secret.encode(),
                json.dumps(data, sort_keys=True).encode(),
                hashlib.sha256
            ).hexdigest()
            
            return hmac.compare_digest(signature, expected_signature)
        except:
            return False
EOF

# Create NOWPayments views with proper IPN handling
cat > /opt/fleio/billing/views/nowpayments.py << 'EOF'
"""
NOWPayments views for Fleio with IPN callback support
"""

from django.shortcuts import render, get_object_or_404, redirect
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.conf import settings
from django.contrib import messages
from django.utils.decorators import method_decorator
from django.views import View
import json
import logging
import hashlib
import hmac
import requests
from decimal import Decimal

from fleio.billing.models import Invoice, Transaction
from fleio.billing.payment_processors.nowpayments import NOWPaymentsProcessor

logger = logging.getLogger(__name__)


class NOWPaymentsCreatePaymentView(View):
    """Create a NOWPayments payment for an invoice"""
    
    def get(self, request, invoice_id):
        try:
            invoice = get_object_or_404(Invoice, id=invoice_id)
            
            processor = NOWPaymentsProcessor()
            payment_info, error = processor.create_payment(
                invoice=invoice,
                amount=invoice.balance,
                currency=invoice.currency.code
            )
            
            if error:
                messages.error(request, f'Payment creation failed: {error}')
                return redirect('billing:invoice_detail', invoice_id=invoice_id)
            
            # Store payment info in session for redirect
            request.session['nowpayments_payment'] = {
                'payment_id': payment_info.get('payment_id'),
                'pay_address': payment_info.get('pay_address'),
                'pay_amount': payment_info.get('pay_amount'),
                'pay_currency': payment_info.get('pay_currency'),
                'invoice_id': invoice_id
            }
            
            return render(request, 'billing/nowpayments/payment.html', {
                'payment_info': payment_info,
                'invoice': invoice
            })
            
        except Exception as e:
            logger.error(f'Error creating NOWPayments payment: {str(e)}')
            messages.error(request, 'Internal server error')
            return redirect('billing:invoice_detail', invoice_id=invoice_id)


@csrf_exempt
@require_http_methods(["POST"])
def nowpayments_ipn_callback(request):
    """Handle NOWPayments IPN callback with proper signature verification"""
    try:
        # Get the raw request body
        raw_body = request.body.decode('utf-8')
        
        # Get signature from headers
        signature = request.META.get('HTTP_X_NOWPAYMENTS_SIG', '')
        
        # Parse request data
        try:
            data = json.loads(raw_body)
        except json.JSONDecodeError:
            logger.error('Invalid JSON in NOWPayments IPN callback')
            return HttpResponse('Invalid JSON', status=400)
        
        # Verify signature using HMAC-SHA256
        if not verify_nowpayments_signature(raw_body, signature):
            logger.warning('Invalid NOWPayments IPN signature')
            return HttpResponse('Invalid signature', status=400)
        
        # Process payment
        payment_id = data.get('payment_id')
        payment_status = data.get('payment_status')
        order_id = data.get('order_id')
        pay_amount = data.get('pay_amount')
        pay_currency = data.get('pay_currency')
        
        logger.info(f'Processing NOWPayments IPN: {payment_id}, status: {payment_status}, order: {order_id}')
        
        if order_id and order_id.startswith('fleio_invoice_'):
            invoice_id = order_id.replace('fleio_invoice_', '')
            try:
                invoice = Invoice.objects.get(id=invoice_id)
                
                if payment_status == 'finished':
                    # Create transaction record
                    transaction, created = Transaction.objects.get_or_create(
                        invoice=invoice,
                        transaction_id=payment_id,
                        defaults={
                            'amount': Decimal(str(pay_amount)),
                            'currency': pay_currency,
                            'status': 'completed',
                            'gateway': 'NOWPayments',
                            'gateway_transaction_id': payment_id
                        }
                    )
                    
                    if created:
                        # Mark invoice as paid
                        invoice.mark_as_paid(
                            amount=invoice.balance,
                            payment_method='NOWPayments',
                            transaction_id=payment_id
                        )
                        logger.info(f'Invoice {invoice_id} marked as paid via NOWPayments')
                    else:
                        logger.info(f'Transaction {payment_id} already processed')
                        
                elif payment_status == 'failed':
                    # Handle failed payment
                    Transaction.objects.update_or_create(
                        invoice=invoice,
                        transaction_id=payment_id,
                        defaults={
                            'amount': Decimal(str(pay_amount)),
                            'currency': pay_currency,
                            'status': 'failed',
                            'gateway': 'NOWPayments',
                            'gateway_transaction_id': payment_id
                        }
                    )
                    logger.info(f'Payment {payment_id} failed for invoice {invoice_id}')
                
            except Invoice.DoesNotExist:
                logger.error(f'Invoice {invoice_id} not found for NOWPayments payment {payment_id}')
        else:
            logger.warning(f'Invalid order_id format: {order_id}')
        
        return HttpResponse('OK', status=200)
        
    except Exception as e:
        logger.error(f'Error processing NOWPayments IPN callback: {str(e)}')
        return HttpResponse('Internal server error', status=500)


def verify_nowpayments_signature(raw_body, signature):
    """Verify NOWPayments IPN signature"""
    try:
        # Get IPN secret from settings
        ipn_secret = getattr(settings, 'NOWPAYMENTS_IPN_SECRET', '')
        if not ipn_secret:
            logger.error('NOWPayments IPN secret not configured')
            return False
        
        # Create expected signature
        expected_signature = hmac.new(
            ipn_secret.encode('utf-8'),
            raw_body.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
        
        # Compare signatures
        return hmac.compare_digest(signature, expected_signature)
        
    except Exception as e:
        logger.error(f'Error verifying NOWPayments signature: {str(e)}')
        return False


@require_http_methods(["GET"])
def nowpayments_payment_status(request, payment_id):
    """Check payment status"""
    try:
        processor = NOWPaymentsProcessor()
        payment_info = processor.verify_payment(payment_id)
        
        if payment_info:
            return JsonResponse({
                'status': 'success',
                'payment_info': payment_info
            })
        else:
            return JsonResponse({
                'status': 'error',
                'message': 'Payment not found'
            }, status=404)
            
    except Exception as e:
        logger.error(f'Error checking payment status: {str(e)}')
        return JsonResponse({
            'status': 'error',
            'message': 'Internal server error'
        }, status=500)
EOF

echo "NOWPayments integration setup complete"
